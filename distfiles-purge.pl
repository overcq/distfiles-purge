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
#===============================================================================
sub Q_files_I_map_extension
{   local $_ = shift;
    s`\.(?:bz2?|deb|gz|jar|rpm|tar(?:\.(?:bz2?|gz|xz))?|t(?:bz2?|gz)|xz|zip)$``s;
    return $_;
}
#-------------------------------------------------------------------------------
sub Q_files_I_split
{   return split /[-_.]/, shift;
}
sub Q_files_I_sort_I_cmp
{   my @a_ = Q_files_I_split( $b );
    my @b_ = Q_files_I_split( $a );
    return @a_ <=> @b_ if @a_ <=> @b_;
    for( my $i = 0; $i != @a_; $i++ )
    {   if( $a_[ $i ] =~ /^[0-9]+$/
        and  $b_[ $i ] =~ /^[0-9]+$/
        )
        {   return $a_[ $i ] <=> $b_[ $i ] if $a_[ $i ] <=> $b_[ $i ];
        }else
        {   return $a_[ $i ] cmp $b_[ $i ] if $a_[ $i ] cmp $b_[ $i ];
        }
    }
    return 0;
}
#-------------------------------------------------------------------------------
sub Q_files_I_after_root_index
{   my $i;
    for( $i = 0; $i != @_; $i++ )
    {   return $i if $_[ $i ] !~ /^[_a-z]/is;
    }
    return $i;
}
my @Q_files_I_grep_last_S_last;
sub Q_files_I_grep_last
{   local @_ = Q_files_I_split(shift);
    my $after_root_index = Q_files_I_after_root_index( @_ );
    my $ret = 0;
    if( $after_root_index == @Q_files_I_grep_last_S_last )
    {   my $i;
        for( $i = 0; $i != $after_root_index; $i++ )
        {   if( $_[ $i ] ne $Q_files_I_grep_last_S_last[ $i ] )
            {   last;
            }
        }
        $ret = !$ret if $i == $after_root_index;
    }elsif( !@Q_files_I_grep_last_S_last )
    {   $ret = !$ret;
    }
    @Q_files_I_grep_last_S_last = ( @_ );
    splice @Q_files_I_grep_last_S_last, $after_root_index;
    return $ret;
}
#===============================================================================
chdir $directory_distfiles || die "Cannot change directory to distfiles: $!";
opendir( my $dh, '.' ) || die "Cannot open distfiles directory: $!";
my @files = grep { !/(?:^\.|\.__download__$)/ } readdir( $dh );
closedir $dh;
my @checksum_failure = grep( /\._checksum_failure_\.[_0-9a-z]+$/, @files );
@files = grep { Q_files_I_grep_last( $_ ) } sort Q_files_I_sort_I_cmp grep { !/\._checksum_failure_\.[_0-9a-z]+$/ } @files;
unlink @checksum_failure;
mkdir $directory_tmp_distfiles || die "Cannot create temporary distfiles directory: $!";
system( 'mv', $_, $directory_tmp_distfiles ) foreach ( @files );
#*******************************************************************************
