package MyApp::Class;

use strict;
use warnings;
use feature qw(:5.10);

use B::Hooks::AtRuntime qw(after_runtime);
use File::Spec;
use Import::Into;
use Module::Runtime qw(require_module);
use String::CamelCase qw(decamelize);

my $APP_CLASS = __PACKAGE__ =~ s/::Class$//r; # MyApp
my $APP_HOME  = Cwd::realpath(File::Spec->catdir(File::Basename::dirname(__FILE__), "../.."));
my @COMMONS = (
    [ "Module::Runtime", qw(require_module use_module) ],
);

sub import {
    my ($caller, $filename) = caller;
    $filename = Cwd::realpath($filename);

    if ( $filename =~ /$APP_HOME/ ) {
        my $rel = File::Spec->abs2rel($filename, $APP_HOME);
        # lib/ 以下では package の記述を省略 lib/MyApp/Web/Controller/Root.pm -> MyApp::Web::Controller::Root
        if ( $rel =~ m{^lib/(.*)} ) {
            my $pkg = $1 =~ s{/}{::}gr =~ s/\.pm//r;
            unless ( $caller eq $pkg ) {
                require B::Hooks::Parser;
                B::Hooks::Parser::inject("; package $pkg;");
                $caller = $pkg;
            }
        }
    }

    # uss utf8; use strict; use feature qw(:5.10) を省略
    utf8->import;
    strict->import;
    feature->import(':5.10');

    my %seen;
    my @loads;
    my @imports;
    my @extends;

    if ($caller =~ /^${APP_CLASS}::Web$/) {
        push @imports, ["Moose"];
        push @extends, ["Catalyst"];
    }
    elsif ($caller =~ /^${APP_CLASS}::Form\b/) {
        push @imports, ["HTML::FormHandler::Moose"];
        push @extends, ["HTML::FormHandler"];
    }
    elsif ($caller =~ /^${APP_CLASS}::Web::Controller\b/) {
        push @imports, ["Moose"];
        push @extends, ["Catalyst::Controller"];
    }

    for my $pkg (@loads) {
        require_module($pkg) unless $seen{$pkg}++;
    }
    for my $args (@COMMONS, @imports) {
        my ($class, @args) = @$args;
        require_module($class) unless $seen{$class}++;
        $class->import::into($caller, @args);
    }
    for my $args (@extends) {
        $caller->meta->superclasses(@$args);
    }

    # 律儀に autoclean するには
    # namespace::autoclean->import( -cleanee => $caller );

    # namespace::autoclean だと遅い場合は次でもおけ
    # namespace::clean->import(
    #     -cleanee => $caller,
    #     -except  => 'meta',
    # );

    # Controller は自動で namespace を設定する
    if ( $caller->isa('Catalyst::Controller') ) {
        # use MyApp::Class の最後 1; の後のランタイムフェーズで評価するには after_runtime {}
        after_runtime {
            unless ( exists $caller->config->{namespace} ) {
                my $suffix = Catalyst::Utils::class2classsuffix($caller);
                state $map = {
                    "Controller::Root" => '',
                };
                $caller->config->{namespace} = $map->{$suffix} // decamelize $suffix =~ s/^Controller:://r;
            }
        }
    }

    # 自動で __PACKAGE__->meta->make_immutable
    if ( $caller->isa('Moose::Object') and $caller->meta->is_mutable ) {
        after_runtime {
            $caller->meta->make_immutable;
        }
    }
}

1;
