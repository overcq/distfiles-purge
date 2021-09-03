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
sub Q_files_I_prepare_name
{   local $_ = shift;
    s`%([0-9a-f]{2})` chr( oct( "0x$1" )) `egis;
    s`\.(?:bz2?|crate|deb|exe|gz|jar|patch(?:.(?:bz2?|gz|xz|zip))?|rpm|tar(?:\.(?:bz2?|gz|xz))?|t(?:bz2?|gz|xz)|xz|zip)$``is;
    return $_;
}
sub Q_files_I_split
{   local $_ = shift;
    s`\+{2}`%2B%2B`gs;
    s`\+([-_.])`%2B$1`gs;
    return split /[-_.+]/;
}
#-------------------------------------------------------------------------------
sub Q_files_I_sort_split
{   local @_ = Q_files_I_split(shift);
    my $before_numeric = 1;
    for( my $i = 0; $i != @_; $i++ )
    {   if( $before_numeric )
        {   if( $_[ $i ] =~ /^([a-z]+)([0-9]+)$/is )
            {   splice @_, $i, 1, $1, $2;
                $i++;
            }elsif( $_[ $i ] !~ /^[a-z]/is )
            {   $before_numeric = !$before_numeric;
            }
        }
    }
    return map { lc } @_;
}
sub Q_files_I_sort_I_cmp
{   my @a_ = Q_files_I_sort_split( Q_files_I_prepare_name( $b ));
    my @b_ = Q_files_I_sort_split( Q_files_I_prepare_name( $a ));
    my $ret = grep( /^[a-z]/is, @a_ ) <=> grep( /^[a-z]/is, @b_ );
    return $ret if $ret;
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
{   local @_ = Q_files_I_split(shift);
    my $before_numeric = 1;
    for( my $i = 0; $i != @_; $i++ )
    {   if( $before_numeric )
        {   if( $_[ $i ] =~ /^([a-z]+)[0-9]+$/is )
            {   $before_numeric = !$before_numeric;
                splice @_, $i, 1, $1;
            }elsif( $_[ $i ] !~ /^[a-z]/is )
            {   $before_numeric = !$before_numeric;
                splice @_, $i, 1;
                $i--;
            }
        }elsif( $_[ $i ] !~ /^[a-z]+$/is
        or $_[ $i ] =~ /^(?:alpha|patches|rc)$/is
        )
        {   splice @_, $i, 1;
            $i--;
        }
    }
    return map { lc } @_;
}
my @Q_files_I_grep_last_S_last;
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
    #print "${ret}: ${file_root}: ". join( '-', @_ ) . ' CMP '. join( '-', @Q_files_I_grep_last_S_last );
    @Q_files_I_grep_last_S_last = @_;
    return $ret;
}
#===============================================================================
chdir $directory_distfiles || die "Cannot change directory to distfiles: $!";
#-------------------------------------------------------------------------------
opendir( my $dh, '.' ) || die "Cannot open distfiles directory: $!";
my @files = grep { !/(?:^\.|\.__download__$)/s } readdir( $dh );
closedir $dh;
my @checksum_failure = grep( /\._checksum_failure_\.[_0-9a-z]+$/s, @files );
@files = grep { Q_files_I_grep_last( $_ ) } sort Q_files_I_sort_I_cmp grep { !/\._checksum_failure_\.[_0-9a-z]+$/s } @files;
#-------------------------------------------------------------------------------
unlink @checksum_failure;
mkdir $directory_tmp_distfiles || die "Cannot create temporary distfiles directory: $!";
system( 'mv', $_, $directory_tmp_distfiles ) foreach ( @files );
#*******************************************************************************
