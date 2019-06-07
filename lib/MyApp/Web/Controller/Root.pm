use MyApp::Class;

sub default :Private {
    my ($self, $c) = @_;

    my $uri = $c->uri_for('/form/sample');
    $c->res->content_type("text/html");
    $c->res->body( <<~"" );
        time @{[ time ]} <a href="$uri">$uri</a>

}

1;
