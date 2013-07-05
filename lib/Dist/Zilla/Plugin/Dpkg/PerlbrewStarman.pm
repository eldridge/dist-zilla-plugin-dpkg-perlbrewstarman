package Dist::Zilla::Plugin::Dpkg::PerlbrewStarman;
use Moose;

use Moose::Util::TypeConstraints;

extends 'Dist::Zilla::Plugin::Dpkg';

enum 'WebServer', [qw(apache nginx all)];
subtype 'ApacheModule', as 'Str', where { $_ =~ /^[a-z_]+$/ };
subtype 'ApacheModules', as 'ArrayRef[ApacheModule]',
    message { 'The value provided for apache_modules does not look like a list of whitespace-separated Apache modules' };
coerce 'ApacheModules', from 'Str', via { [ split /\s+/ ] };

use File::ShareDir qw(dist_file);

sub share_file {
    do { local (@ARGV,$/) = dist_file('Dist-Zilla-Plugin-Dpkg-PerlbrewStarman',shift); <> }
}

#ABSTRACT: Generate dpkg files for your perlbrew-backed, starman-based perl app

=head1 SYNOPSIS

A minimal directory structure for application foo:

    lib/
    root/
    script/foo.psgi
    config/nginx/foo.conf
    perlbrew/bin/starman

A minimal configuration:

    [Dpkg::PerlbrewStarman]
    web_server      = nginx
    starman_port    = 6000

A configuration showing optional attributes and their defaults:

    [Dpkg::PerlbrewStarman]
    web_server      = nginx
    starman_port    = 6000
    psgi_script     = script/foo.psgi
    starman_workers = 5
    startup_time    = 30

A configuration showing optional attributes that have no defaults:

    [Dpkg::PerlbrewStarman]
    web_server      = apache
    starman_port    = 6000
    apache_modules  = ldap ssl
    uid             = 782

=head1 DESCRIPTION

This L<Dist::Zilla> plugin generates Debian control files that are
suitable for packaging a self-contained Plack application utilizing the
Starman preforking PSGI HTTP server.  Key features include supporting an
independent perl environment and the generation and installation of init
scripts to manage the service.

Dist::Zilla::Plugin::Dpkg::PerlbrewStarman is an implementation of
L<Dist::Zilla::Plugin::Dpkg>, which itself is an abstract base class
more than anything.  It provides the basic framework by which this
Dist::Zilla plugin builds the Debian control files.  If the desired
functionality cannot be achieved by PerlbrewStarman, check there for
other control templates that may be overridden.

Dist::Zilla::Plugin::Dpkg::PerlbrewStarman provides defaults for the following
L<Dist::Zilla::Plugin::Dpkg> stubs. The defaults are located in the share
directory of this distribution:

=over 4

=item * conffiles_template_default

=item * control_template_default

=item * default_template_default

=item * init_template_default

=item * install_template_default

=item * postinst_template_default

=item * postrm_template_default

=back

PerlbrewStarman is intended to be used to deploy applications that meet
the following requirements:

=over 4

=item * L<perlbrew> -- others have reported using PerlbrewStarman under other systems (e.g., L<Carton>)

=item * Plack/PSGI using the L<Starman> preforking HTTP server listening on localhost

=item * Apache and/or nginx are utilized as front-end HTTP proxies

=item * Application may be preloaded (using Starman's --preload-app)

=item * Application does not require root privileges

=back

=head2 Directory structure

The package is installed under C</srv/$PACKAGE>.  Though Debian policy
generally forbids packages from installing into /srv, PerlbrewStarman
was written for third-party distribution, not for inclusion into Debian.
This may change.

By default, your application must conform to the following directory
structure:

=over 4

=item * perl environment in C<perlbrew>

=item * application configuration in C<config>

=item * Apache and/or nginx configuration in C<config/apache/$PACKAGE.conf> and/or C<config/nginx/$PACKAGE.conf>

=item * PSGI and other application scripts in C<script>

=item * application libraries in C<lib>

=item * application templates in C<root>

=back

Only files located in these directories will be installed.  Additional
files may be added to the is list by specifying a path to an alternative
install control file using C<install_template>.  The default install
template looks like this:

    config/* srv/{$package_name}/config
    lib/* srv/{$package_name}/lib
    root/* srv/{$package_name}/root
    script/* srv/{$package_name}/script
    perlbrew/* srv/{$package_name}/perlbrew

The package name is substituted for {$package_name} by Text::Template
via L<Dist::Zilla::Plugin::Dpkg>.

Paths may also be removed, but note that the only path in the default
directory structure that is not utilized elsewhere by PerlbrewStarman
is C<root/*>.

=head2 Other paths

PerlbrewStarman creates a number of files under C</etc> in order to
integrate with init as well as the front-end HTTP proxy.  The directory
C</var/log/$PACKAGE> and the link C</etc/$PACKAGE> are created as
normalized locations for log files and app configuration, respectively.
These paths should be intuitively familiar for most UNIX administrators.

Following is a complete list of files and symlinks created:

=over 4

=item * /etc/init.d/$PACKAGE

=item * /etc/default/$PACKAGE

=item * /var/log/$PACKAGE

=item * /etc/apache2/sites-available/$PACKAGE => /srv/$PACKAGE/config/apache/$PACKAGE.conf

=item * /etc/nginx/sites-available/$PACKAGE => /srv/$PACKAGE/config/nginx/$PACKAGE.conf

=item * /etc/$PACKAGE => /srv/$PACKAGE/config

=back

=head2 Environment

By default, C</srv/$PACKAGE/perlbrew/bin> is prepended to the C<PATH> by
way of the C<PERLBREW_PATH> variable in C</etc/default/$PACKAGE>.  The
C<starman> binary must be present in the path, else the service will
fail to start.

The application runs as user $PACKAGE by way of the --user argument to
L<Starman>.  Starman flags are specified by the C<DAEMON_ARGS> variable
in C</etc/default/$PACKAGE>.

=cut

has '+conffiles_template_default' => (
    default => sub { share_file('conffiles_template_default') }
);

has '+control_template_default' => (
    default => sub { share_file('control_template_default') }
);

has '+default_template_default' => (
    default => sub { share_file('default_template_default') }
);

has '+init_template_default' => (
    default => sub { share_file('init_template_default') }
);

has '+install_template_default' => (
    default => sub { share_file('install_template_default') }
);

has '+postinst_template_default' => (
    default => sub { share_file('postinst_template_default') }
);

has '+postrm_template_default' => (
    default => sub { share_file('postrm_template_default') }
);

has '+rules_template_default' => (
    default => sub { share_file('rules_template_default') }
);

=attr starman_port

The port to use for starman (required).

=cut

has 'starman_port' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

=attr starman_workers

The number of starman workers (5 by default).

=cut

has 'starman_workers' => (
    is => 'ro',
    isa => 'Str',
    default => 5
);

=attr psgi_script

Location of the psgi script started by starman. By default this is
C<script/$PACKAGE.psgi>.

=cut

has 'psgi_script' => (
    is => 'ro',
    isa => 'Str',
    default => sub {
        'script/'.$_[0]->package_name.'.psgi';
    }
);

=attr startup_time

The amount of time (in seconds) that the init script will wait on startup. Some
applications may require more than the default amount of time (30 seconds).

=cut

has 'startup_time' => (
    is => 'ro',
    isa => 'Str',
    default => 30
);

=attr uid

The UID of the user we're adding for the package. This is helpful for syncing
UIDs across multiple installations

=cut

has 'uid' => (
  is => 'ro',
  isa => 'Int',
  predicate => 'has_uid'
);

=attr web_server

Set the web server we'll be working with for this package (required).
Supported values are C<apache>, C<nginx>, and C<all> for both..

=cut

has 'web_server' => (
    is => 'ro',
    isa => 'WebServer',
    required => 1
);

=attr apache_modules

Set any additional Apache modules that will need to be enabled.

=cut

has 'apache_modules' => (
    is => 'ro',
    isa => 'ApacheModules',
    required => 0,
    coerce => 1
);

around '_generate_file' => sub {
    my $orig = shift;
    my $self = shift;
    my $file = shift;
    my $required = shift;
    my $vars = shift;

    if($self->has_uid) {
        $vars->{uid} = '--uid '.$self->uid;
    }

    $vars->{starman_port} = $self->starman_port;
    $vars->{starman_workers} = $self->starman_workers;
    $vars->{startup_time} = $self->startup_time;

    if(($self->web_server eq 'apache') || ($self->web_server eq 'all')) {
        $vars->{package_binary_depends} .= ', apache2';
        $vars->{webserver_config_link} .= '# Symlink to the apache config for this environment
        rm -f /etc/apache2/sites-available/$PACKAGE
        ln -s /srv/$PACKAGE/config/apache/$PACKAGE.conf /etc/apache2/sites-available/$PACKAGE
';
        $vars->{webserver_restart} .= 'a2enmod proxy proxy_http rewrite ';
        $vars->{webserver_restart} .= join ' ', @{ $self->apache_modules || [] };
        $vars->{webserver_restart} .= '
        a2ensite $PACKAGE
        mkdir -p /var/log/apache2/$PACKAGE
        if which invoke-rc.d >/dev/null 2>&1; then
            invoke-rc.d apache2 restart
        else
            /etc/init.d/apache2 restart
        fi
';
    }
    if(($self->web_server eq 'nginx') || ($self->web_server eq 'all')) {
        $vars->{package_binary_depends} .= ', nginx';
        $vars->{webserver_config_link} .= '# Symlink to the nginx config for this environment
        rm -f /etc/nginx/sites-available/$PACKAGE
        ln -s /srv/$PACKAGE/config/nginx/$PACKAGE.conf /etc/nginx/sites-available/$PACKAGE
';
        $vars->{webserver_restart} .= 'if which invoke-rc.d >/dev/null 2>&1; then
            invoke-rc.d nginx restart
        else
            /etc/init.d/nginx restart
        fi
';
    }
    $self->$orig($file, $required, $vars);
};

=head1 SEE ALSO

* L<Dist::Zilla::Plugin::ChangelogFromGit::Debian>
* L<Dist::Zilla::Deb>

=cut

1;
