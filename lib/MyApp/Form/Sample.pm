use MyApp::Class;

has_field number => (
    type     => "Integer",
    required => 1,
);

has_field submit => (
    type     => "Submit",
    value    => "calc",
);

1;
