use MyApp::Class;

sub sample :Local {
    my ($self, $c) = @_;

    my $form = use_module("MyApp::Form::Sample")->new;
    $form->process( params => $c->req->params, ctx => $c );

    if ($form->validated) {
        $form->success_message( "@{[ $form->values->{number} ]} * 2 is @{[ $form->values->{number}*2 ]}" );
    }

    $c->res->content_type("text/html; charset=utf-8");
    $c->res->body( $form->render );
}

1;
