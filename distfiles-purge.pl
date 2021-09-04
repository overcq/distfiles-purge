#!/usr/bin/perl -w
#*******************************************************************************
#   ___   publicplace
#  ¦OUX¦  Perl
#  ¦/C+¦  programy narzędziowe systemu
#   ---   oczyszczacz distfiles
#         program główny
# ©overcq                on ‟Gentoo Linux 17.1” “x86_64”             2021‒8‒30 h
#*******************************************************************************
use warnings;
use strict;
use sigtrap qw(die INT QUIT TERM);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $directory_distfiles = '/usr/portage/distfiles';
my $directory_tmp_distfiles = '/var/tmp/portage/distfiles';
my $ignore_after_numeric = 'alpha|rc|source|src';
my $patches = 'patch(?:es|set)?|bug';
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my @Q_files_I_grep_last_S_last;
my @files_preserve;
#===============================================================================
sub Q_files_I_prepare_name
{   local $_ = shift;
    s`%([0-9a-f]{2})` chr( oct( "0x$1" )) `egis;
    s`\.(?:bz2?|crate|deb|exe|gz|jar|rpm|tar(?:\.(?:bz2?|gz|xz))?|t(?:bz2?|gz|xz)|xz|zip)$``is;
    return $_;
}
sub Q_files_I_split
{   local $_ = shift;
    s`\+{2}`plusplus`gs;
    s`\+([-_.])`plus$1`gs;
    return split /[-_.+]/, lc;
}
#-------------------------------------------------------------------------------
sub Q_files_I_sort_split
{   my @a = Q_files_I_split(shift);
    local @_ = @a;
    my $before_numeric = 1;
    for( my $i = 0; $i != @_; $i++ )
    {   if( $before_numeric )
        {   if( $_[ $i ] =~ /^([a-z]+)([0-9]+)$/s )
            {   splice @_, $i, 1, $1, $2;
                $i++;
            }elsif( $_[ $i ] !~ /^[a-z]/s )
            {   $before_numeric = !$before_numeric;
            }
        }
    }
    return @_ ? @_ : ( $a[0] );
}
sub Q_files_I_sort_I_cmp
{   my @a_ = Q_files_I_sort_split( Q_files_I_prepare_name( $b ));
    my @b_ = Q_files_I_sort_split( Q_files_I_prepare_name( $a ));
    my @a__ = grep { $_ =~ /^[a-z]+$/s and $_ !~ /^(?:${ignore_after_numeric})$/s } @a_;
    my @b__ = grep { $_ =~ /^[a-z]+$/s and $_ !~ /^(?:${ignore_after_numeric})$/s } @b_;
    my $ret =  @a__ <=> @b__;
    return $ret if $ret;
    for( my $i = 0; $i != @a__; $i++ )
    {   $ret = $a__[ $i ] cmp $b__[ $i ];
        return $ret if $ret;
    }
    for( my $i = 0; $i != @a_ and $i != @b_; $i++ )
    {   if( $a_[ $i ] =~ /^[0-9]+$/
        and  $b_[ $i ] =~ /^[0-9]+$/
        )
        {   $ret = $a_[ $i ] <=> $b_[ $i ];
            return $ret if $ret;
        }else
        {   $ret = $a_[ $i ] cmp $b_[ $i ];
            return $ret if $ret;
        }
    }
    return @a_ <=> @b_;
}
#-------------------------------------------------------------------------------
sub Q_files_I_grep_split
{   my @a = Q_files_I_split(shift);
    local @_ = @a;
    my $before_numeric = 1;
    for( my $i = 0; $i != @_; $i++ )
    {   if( $before_numeric )
        {   if( $_[ $i ] =~ /^([a-z]+)[0-9]+$/s )
            {   $before_numeric = !$before_numeric;
                splice @_, $i, 1, $1;
            }elsif( $_[ $i ] !~ /^[a-z]/s )
            {   $before_numeric = !$before_numeric;
                splice @_, $i, 1;
                $i--;
            }
        }elsif( $_[ $i ] !~ /^[a-z]+$/s
        or $_[ $i ] =~ /^(?:${ignore_after_numeric})$/s
        )
        {   splice @_, $i, 1;
            $i--;
        }
    }
    return @_ ? @_ : ( $a[0] );
}
sub Q_files_I_grep_last
{   my $file_root = Q_files_I_prepare_name(shift);
    local @_ = Q_files_I_grep_split( $file_root );
    my $ret = 0;
    if( @_ == @Q_files_I_grep_last_S_last )
    {   my $i;
        for( $i = 0; $i != @_; $i++ )
        {   if( $_[ $i ] ne $Q_files_I_grep_last_S_last[ $i ] )
            {   last;
            }
        }
        $ret = !$ret if $i == @_;
    }
    #local $\ = $/;
    #print "A: ${ret}: ${file_root}: ". join( '-', @_ ) . ' CMP '. join( '-', @Q_files_I_grep_last_S_last );
    @Q_files_I_grep_last_S_last = @_;
    return $ret;
}
#-------------------------------------------------------------------------------
sub Q_files_I_grep_patch_I_root_ver
{   my @root_ver;
    my $before_numeric = 1;
    foreach( @_ )
    {   if( $before_numeric )
        {   $before_numeric = !$before_numeric if /^[0-9]+$/;
        }elsif( /^[a-z]/ )
        {   last;
        }
        push @root_ver, $_;
    }
    return @root_ver;
}
sub Q_files_I_grep_patch
{   my $file_root = Q_files_I_prepare_name(shift);
    local @_ = Q_files_I_split( $file_root );
    my $ret = grep /^(?:${patches})$/, @_;
    return $ret unless $ret;
    my @root_ver = Q_files_I_grep_patch_I_root_ver( @_ );
    $ret = 1;
    foreach( @files_preserve )
    {   my @a = Q_files_I_split( Q_files_I_prepare_name( $_ ));
        my @root_ver_ = Q_files_I_grep_patch_I_root_ver( @a );
        if( !grep( /^(?:${patches})$/, @a ))
        {   my $i;
            for( $i = 0; $i != @root_ver and $i != @root_ver_; $i++ )
            {   last if $root_ver[ $i ] ne $root_ver_[ $i ];
            }
            $ret = !$ret if $i == @root_ver or $i == @root_ver_;
        }
    }
    return $ret;
}
#===============================================================================
chdir $directory_distfiles || die "Cannot change directory to distfiles: $!";
#-------------------------------------------------------------------------------
opendir( my $dh, '.' ) || die "Cannot open distfiles directory: $!";
my @files = grep { !/(?:^\.|\.__download__$)/s } readdir( $dh );
closedir $dh;
my @checksum_failure = grep( /\._checksum_failure_\.[_0-9a-z]+$/s, @files );
@files = sort Q_files_I_sort_I_cmp grep { !/\._checksum_failure_\.[_0-9a-z]+$/s } @files;
@files_preserve = grep { !Q_files_I_grep_last( $_ ) } @files;
@Q_files_I_grep_last_S_last = ();
@files = grep { Q_files_I_grep_last( $_ ) or Q_files_I_grep_patch( $_ ) } @files;
#-------------------------------------------------------------------------------
unlink @checksum_failure;
mkdir $directory_tmp_distfiles || die "Cannot create temporary distfiles directory: $!";
system( 'mv', $_, $directory_tmp_distfiles ) foreach ( @files );
#*******************************************************************************
