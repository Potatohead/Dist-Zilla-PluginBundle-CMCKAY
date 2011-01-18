package Dist::Zilla::PluginBundle::CMCKAY;
use Moose;
# ABSTRACT: Dist::Zilla configuration the way CMCKAY does it

use Dist::Zilla;
with 'Dist::Zilla::Role::PluginBundle::Easy';

=head1 SYNOPSIS

    # dist.ini
    [@CMCKAY]
    dist = Dist-Zilla-PluginBundle-CMCKAY

=head1 DESCRIPTION

Roughly equivilant to a dist.ini containing

    [@Basic]

    # metadata
    [MetaConfig]
    [MetaJSON]
    #[MetaYAML]

    # versioning
    [NextRelease]
    format = %-5v %{yyyy-MM-dd}d
    [CheckChangesHasContent]
    [PkgVersion]

    # testing
    [PodCoverageTests]
    [PodSyntaxTests]
    [NoTabsTests]
    [EOLTests]
    [CompileTests]

    # Repository
    [Repository]
    git_remote = git://github.com/Potatohead/${lowercase_dist}
    github_http = 0
    [Git::Check]
    allow_dirty =
    [Git::Tag]
    tag_format = %v
    tag_message =
    [BumpVersionFromGit]
    version_regexp = ^(\d+\.\d+)$
    first_version = 0.01

    # documentation
    [PodWeaver]

=cut

has dist => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has is_task => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { shift->dist =~ /^Task-/ ? 1 : 0 },
);

has is_test_dist => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { shift->dist =~ /^Foo-/ ? 1 : 0 },
);

has github_url => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $dist = $self->dist;
        $dist = lc($dist);
        "git://github.com/Potatohead/$dist.git";
    },
);

has extra_plugins => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        [
            # Metadata
            'MetaConfig',
            'MetaJSON',
            # 'MetaYAML', apparently part of @Basic

            # Versioning
            'NextRelease',
            'CheckChangesHasContent',
            'PkgVersion',

            # testing
            'PodCoverageTests',
            'PodSyntaxTests',
            'NoTabsTests',
            'EOLTests',
            'CompileTests',

            # repository
            'Repository',
            'Git::Check',
            'Git::Tag',
            'BumpVersionFromGit',

            # documentation
            $self->is_task ? 'TaskWeaver' : 'PodWeaver',
        ]
    },
);

has plugin_options => (
    is       => 'ro',
    isa      => 'HashRef[HashRef[Str]]',
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my %opts = (
            'NextRelease'   => { format => '%-5v %{yyyy-MM-dd}d' },
            'Repository' => {
                git_remote => $self->github_url,
                github_http => 0,
            },
            'Git::Check' => { allow_dirty =>'' },
            'Git::Tag' => { tag_format => '%v', tag_message => '' },
            'BumpVersionFromGit' => {
                version_regexp => '^(\d+\.\d+)$',
                first_version => '0.01',
            },
        );

        for my $option (keys %{ $self->payload }) {
            next unless $option =~ /^([A-Z][^_]*)_(.+)$/;
            my ($plugin, $plugin_option) = ($1, $2);
            $opts{$plugin} ||= {};
            $opts{$plugin}->{$plugin_option} = $self->payload->{$option};
        }

        return \%opts;
    }
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my $args = $class->$orig(@_);
    return { %{ $args->{payload} }, %{ $args } };
};

sub configure {
    my $self = shift;

    if ($self->is_test_dist)
    {
        $self->add_bundle(
            '@Filter' => {  bundle => '@Basic', remove => ['UploadToCPAN'] }
        );
        $self->add_plugins('FakeRelease');
    }
    else
    {
        # $self->add_bundle('@Basic');
        $self->add_bundle(
            '@Filter' => {  bundle => '@Basic', remove => ['UploadToCPAN'] }
        );
        $self->add_plugins('FakeRelease');
    }

    $self->add_plugins(
        map { [ $_ => ($self->plugin_options->{$_} || {}) ] }
            @{ $self->extra_plugins },
    );
}

=head1 SEE ALSO

L<Dist::Zilla>

=begin Pod::Coverage

    configure

=end Pod::Coverage

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1;
