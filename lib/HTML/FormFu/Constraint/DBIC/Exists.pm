package HTML::FormFu::Constraint::DBIC::Exists;
use Moose;
use MooseX::Attribute::FormFuChained;

extends 'HTML::FormFu::Constraint';

use Carp qw( carp croak );

use HTML::FormFu::Util qw( DEBUG_CONSTRAINTS debug );

has model          => ( is => 'rw', traits  => ['FormFuChained'] );
has resultset      => ( is => 'rw', traits  => ['FormFuChained'] );
has column         => ( is => 'rw', traits  => ['FormFuChained'] );
has method_name    => ( is => 'rw', traits  => ['FormFuChained'] );
has others         => ( is => 'rw', traits  => ['FormFuChained'] );

sub constrain_value {
    my ( $self, $value ) = @_;

	return 1 if !defined $value || $value eq '';

    # get stash 
    my $stash = $self->form->stash;
    
    my $schema;

    if ( defined $stash->{schema} ) {
        $schema = $stash->{schema};
    }
    elsif ( defined $stash->{context} && defined $self->model ) {
        $schema = $stash->{context}->model( $self->model );
    }
    elsif ( defined $stash->{context} ) {
        $schema = $stash->{context}->model;
    }

    if ( !defined $schema ) {
        # warn and die, as errors are swallowed by HTML-FormFu
        carp  'could not find DBIC schema';
        croak 'could not find DBIC schema';
    }

	my $resultset = $self->resultset ? $schema->resultset( $self->resultset )
				  :					   $schema;

    if ( !defined $resultset ) {
        # warn and die, as errors are swallowed by HTML-FormFu
        carp  'could not find DBIC resultset';
        croak 'could not find DBIC resultset';
    }

    if ( my $method_name = $self->method_name ) {
    	return $resultset->$method_name( $value );
    } 
    else {

		my $column = $self->column || $self->parent->name;
		my %others;
		if ( $self->others ) {
			my @others = ref $self->others ? @{ $self->others }
						   : $self->others;
	
			my $params = $self->form->input;

			%others =
                grep {
                    defined && length
                }
                map {
                    $_ => $self->get_nested_hash_value( $params, $_ )
                } @others;
	
		}
	
		my $existing_row = eval {
			$resultset->find( { %others, $column => $value } );
		};
		
		if ( my $error = $@ ) {
			# warn and die, as errors are swallowed by HTML-FormFu
			carp  $error;
			croak $error;
		}
	
		return $existing_row;

    }
}

1;
