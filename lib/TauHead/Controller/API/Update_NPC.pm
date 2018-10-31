package TauHead::Controller::API::Update_NPC;
use Moose;
use Cpanel::JSON::XS ();
use List::Util qw( all );
use Scalar::Util qw( reftype );
use TauHead::Util qw( camel2words );
use Try::Tiny;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

my @npc_fields = (
    'name',
    'slug',
    'genotype',
    'description',
);

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( api admin ));
}

sub index : Path('/api/update_npc') : Args(0) : FormConfig { }

sub index_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub index_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form   = $c->stash->{form};
    my $params = $form->params;
    my $schema = $c->model('DB');
    my $update = $form->valid('submit');
    my $changed;

    my $slug = $params->{slug};
    my $npc = $schema->resultset('NPC')->find_or_new({
        slug => $slug,
    });

    for my $key ( @npc_fields ) {
        $npc->$key( $params->{$key} );
    }

    my @changed_cols = $npc->is_changed;

    if ( $npc->in_storage ) {
        if ( @changed_cols ) {
            if ($update) {
                $changed = 1;
                $npc->update;
            }
            else {
                $form->add_attrs({ class => 'border-danger' });
                $form->element({
                    type    => 'Block',
                    content => 'NPC changed - will update',
                    attrs => {
                        class => 'alert alert-api alert-danger',
                    },
                });

                $npc->discard_changes;
                for my $key ( @changed_cols ) {
                    if ( ! $update ) {
                        $form->get_field({ name => $key })
                            ->add_attrs({ class => 'alert-danger' })
                            ->comment(sprintf("Changed: was '%s'", $npc->$key));
                    }
                }
            }
        }
        else {
            $form->add_attrs({ class => 'border-success' });
            $form->element({
                type    => 'Block',
                content => 'No change required',
                attrs => {
                    class => 'alert alert-api alert-success',
                },
            });
        }
    }
    else { # new npc
        if ($update) {
            $changed = 1;
            $npc->insert;
        }
        else {
            $form->add_attrs({ class => 'border-warning' });
            $form->element({
                type    => 'Block',
                content => 'NPC is new - will be added',
                attrs => {
                    class => 'alert alert-api alert-warning',
                },
            });
        }
    }

    if ( $update ) {
        my $msg = $changed ? "NPC updated" : "No change required";

        # redirect to NPC page
        my $redirect = $c->uri_for( "/npc", $npc->slug, { mid => $c->set_status_msg($msg) } );

        $c->stash->{rest} = {
            ok       => 1,
            redirect => $redirect->as_string,
        };

        $self->add_log( $c, 'api/update_npc',
            {
                description => "API Updated NPC",
            },
        );

        $c->detach;
    }
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
