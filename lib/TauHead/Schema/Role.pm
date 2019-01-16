package TauHead::Schema::Role;
use Moose::Role;

sub api_update_columns {
    my ( $self ) = @_;

    my $info = $self->columns_info;
    my @display;

    for my $col ( $self->columns ) {
        next unless exists $info->{$col}{extra}
            && $info->{$col}{extra}{th_api_update};

        push @display, $col;
    }

    return \@display;
}

sub display_columns {
    my ( $self ) = @_;

    my $info = $self->columns_info;
    my @display;

    for my $col ( $self->columns ) {
        next unless exists $info->{$col}{extra}
            && $info->{$col}{extra}{th_display};

        if ( $info->{$col}{extra}{th_display_ignore_false} ) {
            my $value = $self->get_column($col);

            next if !$value;

            next if $info->{$col}{data_type} eq 'decimal'
                && $value == 0;
        }

        push @display, $col;
    }

    return \@display;
}

sub display_col_vals {
    my ( $self ) = @_;

    my %data = $self->get_columns;
    my @return;

    for my $col ( @{ $self->display_columns } ) {
        push @return, {
            name  => $col,
            value => $data{$col},
        };
    }

    return \@return;
}

sub export_columns {
    my ( $self ) = @_;

    my $info = $self->columns_info;
    my @export;

    for my $col ( $self->columns ) {
        next unless exists $info->{$col}{extra}
            && $info->{$col}{extra}{th_export};

        push @export, $col;
    }

    return \@export;
}

sub export_col_vals {
    my ( $self ) = @_;

    my %data = $self->get_columns;
    my @return;

    for my $col ( @{ $self->export_columns } ) {
        push @return, {
            name  => $col,
            value => $data{$col},
        };
    }

    return \@return;
}

sub json_export_columns {
    my ( $self ) = @_;

    my $info = $self->columns_info;
    my @export;

    for my $col ( $self->columns ) {
        next unless exists $info->{$col}{extra}
            && $info->{$col}{extra}{json_export};

        push @export, $col;
    }

    return \@export;
}

sub json_export_hashref {
    my ( $self ) = @_;

    my %data = $self->get_columns;
    my %return;

    for my $col ( @{ $self->json_export_columns } ) {
        $return{$col} = $data{$col};
    }

    return \%return;
}

1;
