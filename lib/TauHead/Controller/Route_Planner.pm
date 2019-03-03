package TauHead::Controller::Route_Planner;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub route_planner : Path('/route-planner') : Args(0) : FormConfig {
}

sub route_planner_FORM_VALID {
	my ( $self, $c ) = @_;

	my $form       = $c->stash->{form};
	my $start_slug = $form->param_value('start');
	my $end_slug   = $form->param_value('end');

	my $station_rs = $c->model('DB')->resultset('Station');

	my $start = $station_rs->find({ slug => $start_slug });
	my $end   = $station_rs->find({ slug => $end_slug });

	my $this_start = $start;
	my $this_end   = $end;
	my @route;

	if ( $this_start->slug eq $this_end->slug )  {
		@route = ( $this_start );
	}
	elsif ( $this_start->system_slug eq $this_end->system_slug )  {
		@route = ( $this_start, $this_end );
	}
	else {
		@route = $self->_jg_route( $c, $this_start, $this_end );
	}

	$c->stash->{start} = $start;
	$c->stash->{end}   = $end;
	$c->stash->{route} = $self->_route_to_stages( $c, \@route );
	return;
}

sub _jg_route {
	my ( $self, $c, $s1, $s2 ) = @_;
	# returns 1st route found
	# does not attempt to search for shortest route

	my @route = $self->_find_jg_route( $c, $s1, $s2 );
	my @return;
	my $first_jg = $route[0];
	my $last_jg  = $route[-1];

	if ( $s1->slug ne $first_jg->slug ) {
		push @return, $s1;
	}

	push @return, @route;

	if ( $s2->slug ne $last_jg->slug ) {
		push @return, $s2;
	}

	return @return;
}

sub _find_jg_route {
	my ( $self, $c, $s1, $s2, $jg0, $seen ) = @_;
	$seen ||= {};

	# currently assumes a single JG in each system
	my $jg1 = $self->_this_or_same_system_jg( $c, $s1 );
	my $jg2 = $self->_this_or_same_system_jg( $c, $s2 );

	$seen->{ $jg1->slug } = 1;

	my $targets = $jg1->interstellar_destinations;

	for my $target (@$targets) {
		if ( $seen->{ $target->slug }++ ) {
			next;
		}

		if ( $jg0 && ( $jg0->slug eq $target->slug ) ) {
			next;
		}

		if ( $jg2->system_slug eq $target->system_slug ) {
			return $jg1, $target;
		}
		else {
			my @x = $self->_find_jg_route( $c, $target, $s2, ($jg0||$jg1), $seen );
			if ( @x ) {
				return $jg1, @x;
			}
		}
	}
	return;
}

sub _this_or_same_system_jg {
	my ( $self, $c, $sx ) = @_;

	if ( $sx->count_related('interstellar_links') ) {
		return $sx;
	}
	else {
		# currently assumes a single JG in each system
		my $sibling_rs = $c->model('DB')->resultset('Station')->search(
			{
				system_slug => $sx->system_slug,
				slug		=> { '!=' => $sx->slug },
			}
		);
		for my $sibling ( $sibling_rs->all ) {
			if ( $sibling->count_related('interstellar_links') ) {
				return $sibling;
			}
		}
	}

	die sprintf "failed to find a JG in this system: '%d', station: '%d'",
		$sx->system_slug,
		$sx->slug;
}

sub _route_to_stages {
	my ( $self, $c, $route ) = @_;

	my @stage;

	while ( @$route ) {
		my $from = shift @$route;
		my $to   = @$route ? $route->[0] : undef;

		push @stage, { station => $from };

		if ($to) {
			my $stage = {};
			if ( $from->system_slug eq $to->system_slug ) {
				$stage->{local} = 1;
				if ( $from->has_public_shuttles && $to->has_public_shuttles) {
					$stage->{has_public_shuttles} = 1;
				}
			}
			else {
				$stage->{interstellar} = 1;
			}
			push @stage, $stage;
		}
	}
	return \@stage;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
