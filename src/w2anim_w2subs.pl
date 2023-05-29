############################################################################
#
#  W2 Animator
#  W2 Input and Calculation Routines
#  Copyright (c) 2022-2023, Stewart A. Rounds
#
#  Contact:
#    Stewart A. Rounds
#    roundsstewart@gmail.com
#
#  This program is free software; you may redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation, either version 3
#  of the License or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
############################################################################

#
# Subroutines included:
#  read_con
#  read_bth
#  read_bth_slice
#  get_grid_elevations
#  read_w2_met_file
#  read_w2_timeseries
#  read_w2_layer_outflow
#  confirm_w2_ftype
#  scan_w2_spr_file
#  read_w2_spr_file
#  scan_w2_file4segs
#  read_w2_flowtemp
#  read_w2_heatfluxes
#  read_w2_wlopt
#  scan_w2_cpl_file
#  read_w2_cpl_file
#  read_libby_config
#
#  downstream_withdrawal
#
#  libby_calcs
#  howington_flows
#  zbrent_howington
#

use strict;
use warnings;
use diagnostics;

# Shared global variables
our (%grid);


############################################################################
#
# Read a CE-QUAL-W2 control file to get certain inputs
#
sub read_con {
    my ($parent, $id, $confile) = @_;
    my (
        $byear, $fh, $i, $imx, $j, $jd_beg, $jd_end, $kmx, $line, $n, $nn,
        $nal, $nbod, $nbr, $nep, $ngc, $ngt, $niw, $nmc, $npi, $npu, $nsp,
        $nss, $nst, $nstt, $ntr, $nwb, $nwd, $nzp, $old_fmt, $selectc, $tmp,

        @be, @bs, @cpld, @cplf, @dhs, @ds, @elbot, @estrt, @idgt, @idn,
        @idn_list, @idpi, @idpu, @idsp, @iugt, @iup, @iup_list, @iupi, @iupu,
        @iusp, @jbdn, @kbswt, @ktswt, @ncpl, @nspr, @nstr, @sinkc, @slope,
        @sprd, @sprf, @tmp1, @tmp2, @uhs, @us, @vals, @wdod, @wdof, @wstrt,
       );

#   Open the specified W2 control file
    open ($fh, $confile) or
        return &pop_up_error($parent, "Unable to open W2 control file:\n$confile");

#   Clear out the grid hash for this object, just in case
    delete $grid{$id};

#   Clean up some arrays
    @bs = @be = @uhs = @dhs = @us = @ds = ();
    @slope = @elbot = @jbdn = @vals = ();
    @nstr = @ktswt = @kbswt = @sinkc = @estrt = @wstrt = ();
    @iupi = @idpi = @iusp = @idsp = @iugt = @idgt = @iupu = @idpu = ();
    @iup = @idn = ();
    @nspr = @sprd = @sprf = ();
    @ncpl = @cpld = @cplf = ();
    @wdod = @wdof = ();

#   New format file name is "w2_con.csv"
#    whereas original file format name is "w2_con.npt"
    if ($confile =~ /\.csv$/) {

#       Skip the title lines
        for ($j=0; $j<13; $j++) { <$fh>; }

#       Grid info
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        ($nwb, $nbr, $imx, $kmx, @vals) = split(/,/, $line);

#       Inflow and outflow types and numbers
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        ($ntr, $nst, $niw, $nwd, $ngt, $nsp, $npi, $npu) = split(/,/, $line);

#       Numbers of constituents
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        ($ngc, $nss, $nal, $nep, $nbod, $nmc, $nzp) = split(/,/, $line);

#       Misc
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        (undef, $selectc, @vals) = split(/,/, $line);

#       Date info
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        ($jd_beg, $jd_end, $byear) = split(/,/, $line);

#       DLT CON -- skip
        <$fh>; <$fh>; <$fh>;

#       DLT DATE -- skip
        <$fh>; <$fh>; <$fh>;

#       DLT maximum time steps -- skip
        <$fh>; <$fh>; <$fh>;

#       DLT timestep fractions -- skip
        <$fh>; <$fh>; <$fh>;

#       DLT Limits -- skip 3
        <$fh>; <$fh>; for ($j=0; $j<3; $j++) { <$fh>; }

#       Read branch info.  The new format no longer includes UQB or DQB
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        @us    = (undef, split(/,/, $line));
        ($line = <$fh>) =~ s/,+$//;
        @ds    = (undef, split(/,/, $line));
        ($line = <$fh>) =~ s/,+$//;
        @uhs   = (undef, split(/,/, $line));
        ($line = <$fh>) =~ s/,+$//;
        @dhs   = (undef, split(/,/, $line));
        <$fh>;  # skip nl
        ($line = <$fh>) =~ s/,+$//;
        @slope = (undef, split(/,/, $line));
        <$fh>;  # skip slopec

#       Read waterbody info
        <$fh>; <$fh>;
        <$fh>;  # skip lat
        <$fh>;  # skip long
        ($line = <$fh>) =~ s/,+$//;
        @elbot = (undef, split(/,/, $line));
        ($line = <$fh>) =~ s/,+$//;
        @bs    = (undef, split(/,/, $line));
        ($line = <$fh>) =~ s/,+$//;
        @be    = (undef, split(/,/, $line));
        ($line = <$fh>) =~ s/,+$//;
        @jbdn  = (undef, split(/,/, $line));

#       Initial conditions -- skip 4
        <$fh>; <$fh>; for ($j=0; $j<4; $j++) { <$fh>; }

#       Calculations -- skip 6
        <$fh>; <$fh>; for ($j=0; $j<6; $j++) { <$fh>; }

#       Dead sea -- skip 4
        <$fh>; <$fh>; for ($j=0; $j<4; $j++) { <$fh>; }

#       Interpolations -- skip 3
        <$fh>; <$fh>; for ($j=0; $j<3; $j++) { <$fh>; }

#       Heat exchange -- skip 9
        <$fh>; <$fh>; for ($j=0; $j<9; $j++) { <$fh>; }

#       Ice cover -- skip 8
        <$fh>; <$fh>; for ($j=0; $j<8; $j++) { <$fh>; }

#       Transport -- skip 2
        <$fh>; <$fh>; for ($j=0; $j<2; $j++) { <$fh>; }

#       Hydraulic coefficients -- skip 8
        <$fh>; <$fh>; for ($j=0; $j<8; $j++) { <$fh>; }

#       Eddy viscosity -- skip 9
        <$fh>; <$fh>; for ($j=0; $j<9; $j++) { <$fh>; }

#       Number of structures
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        @nstr  = (undef, split(/,/, $line));
        <$fh>;  # skip dynstruc

#       Structure outflow interpolation -- skip
        $nstt = &max(5,$nst);
        for ($n=0; $n<$nstt; $n++) { <$fh>; }

#       Structure upper layer limit
        for ($n=1; $n<=$nstt; $n++) {
            ($line = <$fh>) =~ s/,+$//;
            next if ($n > $nst);
            @vals = split(/,/, $line);
            for ($j=1; $j<=$nbr; $j++) {
                $ktswt[$n][$j] = $vals[$j-1];
            }
        }

#       Structure lower layer limit
        for ($n=1; $n<=$nstt; $n++) {
            ($line = <$fh>) =~ s/,+$//;
            next if ($n > $nst);
            @vals = split(/,/, $line);
            for ($j=1; $j<=$nbr; $j++) {
                $kbswt[$n][$j] = $vals[$j-1];
            }
        }

#       Structure type (line, point)
        for ($n=1; $n<=$nstt; $n++) {
            ($line = <$fh>) =~ s/,+$//;
            next if ($n > $nst);
            @vals = split(/,/, $line);
            for ($j=1; $j<=$nbr; $j++) {
                $sinkc[$n][$j] = $vals[$j-1];
            }
        }

#       Structure centerline elevation
        for ($n=1; $n<=$nstt; $n++) {
            ($line = <$fh>) =~ s/,+$//;
            next if ($n > $nst);
            @vals = split(/,/, $line);
            for ($j=1; $j<=$nbr; $j++) {
                $estrt[$n][$j] = $vals[$j-1];
            }
        }

#       Structure width (for line sinks)
        for ($n=1; $n<=$nstt; $n++) {
            ($line = <$fh>) =~ s/,+$//;
            next if ($n > $nst);
            @vals = split(/,/, $line);
            for ($j=1; $j<=$nbr; $j++) {
                $wstrt[$n][$j] = $vals[$j-1];
            }
        }

#       Pipes
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        @iupi  = (undef, split(/,/, $line));
        ($line = <$fh>) =~ s/,+$//;
        @idpi  = (undef, split(/,/, $line));
        for ($j=0; $j<8; $j++) { <$fh>; }    # skip 8

#       Upstream pipe parameters -- skip 5
        for ($j=0; $j<5; $j++) { <$fh>; }

#       Downstream pipe parameters -- skip 5
        for ($j=0; $j<5; $j++) { <$fh>; }

#       Spillways
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        @iusp  = (undef, split(/,/, $line));
        ($line = <$fh>) =~ s/,+$//;
        @idsp  = (undef, split(/,/, $line));
        for ($j=0; $j<6; $j++) { <$fh>; }    # skip 6

#       Upstream spillway parameters -- skip 5
        for ($j=0; $j<5; $j++) { <$fh>; }

#       Downstream spillway parameters -- skip 5
        for ($j=0; $j<5; $j++) { <$fh>; }

#       Spillway TDG parameters -- skip 5
        for ($j=0; $j<5; $j++) { <$fh>; }

#       Gates
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        @iugt  = (undef, split(/,/, $line));
        ($line = <$fh>) =~ s/,+$//;
        @idgt  = (undef, split(/,/, $line));
        for ($j=0; $j<8; $j++) { <$fh>; }    # skip 8

#       Gate weir parameters -- skip 6
        for ($j=0; $j<6; $j++) { <$fh>; }

#       Upstream gate parameters -- skip 5
        for ($j=0; $j<5; $j++) { <$fh>; }

#       Downstream gate parameters -- skip 5
        for ($j=0; $j<5; $j++) { <$fh>; }

#       Gate TDG parameters -- skip 5
        for ($j=0; $j<5; $j++) { <$fh>; }

#       Pumps
        <$fh>; <$fh>;
        ($line = <$fh>) =~ s/,+$//;
        @iupu  = (undef, split(/,/, $line));
        ($line = <$fh>) =~ s/,+$//;
        @idpu  = (undef, split(/,/, $line));
        for ($j=0; $j<8; $j++) { <$fh>; }    # skip 8

#       More pump parameters -- skip 5
        for ($j=0; $j<5; $j++) { <$fh>; }

#       Internal weirs
        <$fh>; <$fh>;
        for ($j=0; $j<3; $j++) { <$fh>; }    # skip 3

#       Withdrawals
        <$fh>; <$fh>;
        for ($j=0; $j<5; $j++) { <$fh>; }    # skip 5

#       Tributaries, including file names
        <$fh>; <$fh>;
        for ($j=0; $j<8; $j++) { <$fh>; }    # skip 8

#       Distributed tributaries
        <$fh>; <$fh>; <$fh>;

#       Hydraulic parameter print status
        <$fh>; <$fh>;
        for ($j=0; $j<15; $j++) { <$fh>; }   # skip 15

#       Snapshot print (new format selects all segments)
        <$fh>; <$fh>;
        for ($j=0; $j<4; $j++) { <$fh>; }    # skip 4

#       Screen print
        <$fh>; <$fh>;
        for ($j=0; $j<4; $j++) { <$fh>; }    # skip 4

#       Profile output
        <$fh>; <$fh>;
        for ($j=0; $j<6; $j++) { <$fh>; }    # skip 6

#       Spreadsheet output
        <$fh>; <$fh>;
        <$fh>;                               # skip SPRC
        $line = <$fh>;
        if (index($line, ",") >= 0) {
            $tmp = substr($line,0,index($line,",")) +0;
        } else {
            $tmp = $line +0;
        }
        <$fh>;                               # skip NISPR
        $line = <$fh>;
        if (index($line, ",") >= 0) {
            @tmp1 = split(/,/, $line);
        } else {
            $tmp1[0] = $line +0;
        }
        $line = <$fh>;
        if (index($line, ",") >= 0) {
            @tmp2 = split(/,/, $line);
        } else {
            $tmp2[0] = $line +0;
        }
        <$fh>;                               # skip ISPR
        for ($j=1; $j<=$nwb; $j++) {
            $nspr[$j] = $tmp;
            for ($n=1; $j<=$tmp; $j++) {
                $sprd[$n][$j] = $tmp1[$n-1];
                $sprf[$n][$j] = $tmp2[$n-1];
            }
        }

#       Vector output
        <$fh>; <$fh>;
        for ($j=0; $j<4; $j++) { <$fh>; }    # skip 4

#       Contour output
        <$fh>; <$fh>;
        <$fh>;                               # skip CPLC
        $line = <$fh>;
        if (index($line, ",") >= 0) {
            $tmp = substr($line,0,index($line,",")) +0;
        } else {
            $tmp = $line +0;
        }
        <$fh>;                               # skip TECPLOT
        $line = <$fh>;
        if (index($line, ",") >= 0) {
            @tmp1 = split(/,/, $line);
        } else {
            $tmp1[0] = $line +0;
        }
        $line = <$fh>;
        if (index($line, ",") >= 0) {
            @tmp2 = split(/,/, $line);
        } else {
            $tmp2[0] = $line +0;
        }
        for ($j=1; $j<=$nwb; $j++) {
            $ncpl[$j] = $tmp;
            for ($n=1; $j<=$tmp; $j++) {
                $cpld[$n][$j] = $tmp1[$n-1];
                $cplf[$n][$j] = $tmp2[$n-1];
            }
        }

#       Flux output
        <$fh>; <$fh>;
        for ($j=0; $j<4; $j++) { <$fh>; }    # skip 4

#       Time-Series plot output
        <$fh>; <$fh>;
        for ($j=0; $j<8; $j++) { <$fh>; }    # skip 8

#       Water-level output
        <$fh>; <$fh>;
        for ($j=0; $j<2; $j++) { <$fh>; }    # skip 2

#       Flow balance output
        <$fh>; <$fh>;
        for ($j=0; $j<2; $j++) { <$fh>; }    # skip 2

#       N and P mass balance output
        <$fh>; <$fh>;
        for ($j=0; $j<2; $j++) { <$fh>; }    # skip 2

#       Outflow output
        <$fh>; <$fh>;
        <$fh>;                               # skip WDOC
        <$fh>;                               # skip NWDO
        <$fh>;                               # skip NIWDO
        <$fh>;                               # skip WDOFN
        $line = <$fh>;
        if (index($line, ",") >= 0) {
            @wdod = split(/,/, $line);
        } else {
            $wdod[0] = $line +0;
        }
        $line = <$fh>;
        if (index($line, ",") >= 0) {
            @wdof = split(/,/, $line);
        } else {
            $wdof[0] = $line +0;
        }
        <$fh>;                               # skip IWDO


#       Skip the rest for now...


#   Original format
    } else {

#       Skip the title lines
        for ($j=0; $j<13; $j++) { <$fh>; }

#       Grid info
        <$fh>; <$fh>;
        $line = <$fh>;
        $nwb  = &round_to_int(substr($line, 8,8));
        $nbr  = &round_to_int(substr($line,16,8));
        $imx  = &round_to_int(substr($line,24,8));
        $kmx  = &round_to_int(substr($line,32,8));

#       Inflow and outflow types and numbers
        <$fh>; <$fh>;
        $line = <$fh>;
        $ntr  = &round_to_int(substr($line, 8,8));
        $nst  = &round_to_int(substr($line,16,8));
        $niw  = &round_to_int(substr($line,24,8));
        $nwd  = &round_to_int(substr($line,32,8));
        $ngt  = &round_to_int(substr($line,40,8));
        $nsp  = &round_to_int(substr($line,48,8));
        $npi  = &round_to_int(substr($line,56,8));
        $npu  = &round_to_int(substr($line,64,8));

#       Numbers of constituents
        <$fh>; <$fh>;
        $line = <$fh>;
        $ngc  = &round_to_int(substr($line, 8,8));
        $nss  = &round_to_int(substr($line,16,8));
        $nal  = &round_to_int(substr($line,24,8));
        $nep  = &round_to_int(substr($line,32,8));
        $nbod = &round_to_int(substr($line,40,8));
        $nmc  = &round_to_int(substr($line,48,8));
        $nzp  = &round_to_int(substr($line,56,8));

#       Misc
        <$fh>; <$fh>;
        $line    = <$fh>;
        $selectc = substr($line,16,8);

#       Date info
        <$fh>; <$fh>;
        $line   = <$fh>;
        $jd_beg = substr($line, 8,8) +0;
        $jd_end = substr($line,16,8) +0;
        $byear  = &round_to_int(substr($line,24,8));

#       DLT CON card -- skip as much as possible
        <$fh>; <$fh>;
        $line = <$fh>;
        $tmp  = &round_to_int(substr($line,8,8));

#       DLT DATE -- skip
        <$fh>; <$fh>; for ($j=0; $j<$tmp; $j+=9) { <$fh>; }

#       DLT maximum time steps -- skip
        <$fh>; <$fh>; for ($j=0; $j<$tmp; $j+=9) { <$fh>; }

#       DLT timestep fractions -- skip
        <$fh>; <$fh>; for ($j=0; $j<$tmp; $j+=9) { <$fh>; }

#       DLT Limits -- skip
        <$fh>; <$fh>; for ($j=0; $j<$nwb; $j++) { <$fh>; }

#       Read branch info
        <$fh>; $line = <$fh>;
        $old_fmt = ($line =~ /(UQB|DQB)/i && length($line) >= 78) ? 1 : 0;
        for ($j=1; $j<=$nbr; $j++) {
            $line    = <$fh>;
            $us[$j]  = &round_to_int(substr($line, 8,8));
            $ds[$j]  = &round_to_int(substr($line,16,8));
            $uhs[$j] = &round_to_int(substr($line,24,8));
            $dhs[$j] = &round_to_int(substr($line,32,8));
            if ($old_fmt) {
                $slope[$j] = substr($line,64,8) +0;
            } else {
                $slope[$j] = substr($line,48,8) +0;
            }
        }

#       Read waterbody info
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            $line      = <$fh>;
            $elbot[$j] = substr($line,24,8) +0;
            $bs[$j]    = &round_to_int(substr($line,32,8));
            $be[$j]    = &round_to_int(substr($line,40,8));
            $jbdn[$j]  = &round_to_int(substr($line,48,8));
        }

#       Initial conditions -- skip
        <$fh>; <$fh>; for ($j=0; $j<$nwb; $j++) { <$fh>; }

#       Calculations -- skip
        <$fh>; <$fh>; for ($j=0; $j<$nwb; $j++) { <$fh>; }

#       Dead sea -- skip
        <$fh>; <$fh>; for ($j=0; $j<$nwb; $j++) { <$fh>; }

#       Interpolations -- skip
        <$fh>; <$fh>; for ($j=0; $j<$nbr; $j++) { <$fh>; }

#       Heat exchange -- skip
        <$fh>; <$fh>; for ($j=0; $j<$nwb; $j++) { <$fh>; }

#       Ice cover -- skip
        <$fh>; <$fh>; for ($j=0; $j<$nwb; $j++) { <$fh>; }

#       Transport -- skip
        <$fh>; <$fh>; for ($j=0; $j<$nwb; $j++) { <$fh>; }

#       Hydraulic coefficients -- skip
        <$fh>; <$fh>; for ($j=0; $j<$nwb; $j++) { <$fh>; }

#       Eddy viscosity -- skip
        <$fh>; <$fh>; for ($j=0; $j<$nwb; $j++) { <$fh>; }

#       Number of structures
        <$fh>; <$fh>;
        for ($j=1; $j<=$nbr; $j++) {
            $line     = <$fh>;
            $nstr[$j] = &round_to_int(substr($line,8,8));
        }

#       Structure outflow interpolation -- skip
        <$fh>; <$fh>;
        for ($j=1; $j<=$nbr; $j++) {
            if ($nstr[$j] == 0) {
                $line = <$fh>;
            } else {
                for ($n=0; $n<$nstr[$j]; $n+=9) { <$fh>; }
            }
        }

#       Structure upper layer limit
        <$fh>; <$fh>;
        for ($j=1; $j<=$nbr; $j++) {
            if ($nstr[$j] == 0) {
                $line = <$fh>;
            } else {
                for ($i=0; $i<$nstr[$j]; $i+=9) {
                    $line = <$fh>;
                    for ($n=1; $n<=9; $n++) {
                        $nn = $i +$n;
                        $ktswt[$nn][$j] = &round_to_int(substr($line,8*$n,8));
                        last if ($nn >= $nstr[$j]);
                    }
                }
            }
        }

#       Structure lower layer limit
        <$fh>; <$fh>;
        for ($j=1; $j<=$nbr; $j++) {
            if ($nstr[$j] == 0) {
                $line = <$fh>;
            } else {
                for ($i=0; $i<$nstr[$j]; $i+=9) {
                    $line = <$fh>;
                    for ($n=1; $n<=9; $n++) {
                        $nn = $i +$n;
                        $kbswt[$nn][$j] = &round_to_int(substr($line,8*$n,8));
                        last if ($nn >= $nstr[$j]);
                    }
                }
            }
        }

#       Structure type (line, point)
        <$fh>; <$fh>;
        for ($j=1; $j<=$nbr; $j++) {
            if ($nstr[$j] == 0) {
                $line = <$fh>;
            } else {
                for ($i=0; $i<$nstr[$j]; $i+=9) {
                    $line = <$fh>;
                    for ($n=1; $n<=9; $n++) {
                        $nn = $i +$n;
                        $sinkc[$nn][$j] = substr($line,8*$n,8);
                        last if ($nn >= $nstr[$j]);
                    }
                }
            }
        }

#       Structure centerline elevation
        <$fh>; <$fh>;
        for ($j=1; $j<=$nbr; $j++) {
            if ($nstr[$j] == 0) {
                $line = <$fh>;
            } else {
                for ($i=0; $i<$nstr[$j]; $i+=9) {
                    $line = <$fh>;
                    for ($n=1; $n<=9; $n++) {
                        $nn = $i +$n;
                        $estrt[$nn][$j] = substr($line,8*$n,8) +0;
                        last if ($nn >= $nstr[$j]);
                    }
                }
            }
        }

#       Structure width (for line sinks)
        <$fh>; <$fh>;
        for ($j=1; $j<=$nbr; $j++) {
            if ($nstr[$j] == 0) {
                $line = <$fh>;
            } else {
                for ($i=0; $i<$nstr[$j]; $i+=9) {
                    $line = <$fh>;
                    for ($n=1; $n<=9; $n++) {
                        $nn = $i +$n;
                        $wstrt[$nn][$j] = substr($line,8*$n,8) +0;
                        last if ($nn >= $nstr[$j]);
                    }
                }
            }
        }

#       Pipes (particularly the upstream/downstream segment connections)
        <$fh>; <$fh>;
        if ($npi == 0) {
            <$fh>;
        } else {
            for ($j=1; $j<=$npi; $j++) {
                $line = <$fh>;
                $iupi[$j] = substr($line, 8,8) +0;
                $idpi[$j] = substr($line,16,8) +0;
            }
        }

#       Upstream pipe parameters
        <$fh>; <$fh>; <$fh>; for ($j=2; $j<=$npi; $j++) { <$fh>; }

#       Downstream pipe parameters
        <$fh>; <$fh>; <$fh>; for ($j=2; $j<=$npi; $j++) { <$fh>; }

#       Spillways (particularly the upstream/downstream segment connections)
        <$fh>; <$fh>;
        if ($nsp == 0) {
            <$fh>;
        } else {
            for ($j=1; $j<=$nsp; $j++) {
                $line = <$fh>;
                $iusp[$j] = substr($line, 8,8) +0;
                $idsp[$j] = substr($line,16,8) +0;
            }
        }

#       Upstream spillway parameters
        <$fh>; <$fh>; <$fh>; for ($j=2; $j<=$nsp; $j++) { <$fh>; }

#       Downstream spillway parameters
        <$fh>; <$fh>; <$fh>; for ($j=2; $j<=$nsp; $j++) { <$fh>; }

#       Spillway TDG parameters
        <$fh>; <$fh>; <$fh>; for ($j=2; $j<=$nsp; $j++) { <$fh>; }

#       Gates (particularly the upstream/downstream segment connections)
        <$fh>; <$fh>;
        if ($ngt == 0) {
            <$fh>;
        } else {
            for ($j=1; $j<=$ngt; $j++) {
                $line = <$fh>;
                $iugt[$j] = substr($line, 8,8) +0;
                $idgt[$j] = substr($line,16,8) +0;
            }
        }

#       Gate weir parameters
        <$fh>; <$fh>; <$fh>; for ($j=2; $j<=$ngt; $j++) { <$fh>; }

#       Upstream gate parameters
        <$fh>; <$fh>; <$fh>; for ($j=2; $j<=$ngt; $j++) { <$fh>; }

#       Downstream gate parameters
        <$fh>; <$fh>; <$fh>; for ($j=2; $j<=$ngt; $j++) { <$fh>; }

#       Gate TDG parameters
        <$fh>; <$fh>; <$fh>; for ($j=2; $j<=$ngt; $j++) { <$fh>; }

#       Pumps (particularly the upstream/downstream segment connections)
        <$fh>; <$fh>;
        if ($npu == 0) {
            <$fh>;
        } else {
            for ($j=1; $j<=$npu; $j++) {
                $line = <$fh>;
                $iupu[$j] = substr($line, 8,8) +0;
                $idpu[$j] = substr($line,16,8) +0;
            }
        }

#       More pump parameters
        <$fh>; <$fh>; <$fh>; for ($j=2; $j<=$npu; $j++) { <$fh>; }

#       Internal weir segments
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$niw; $j+=9) { <$fh>; }

#       Internal weir top
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$niw; $j+=9) { <$fh>; }

#       Internal weir bottom
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$niw; $j+=9) { <$fh>; }

#       Withdrawal interpolation
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$nwd; $j+=9) { <$fh>; }

#       Withdrawal segments
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$nwd; $j+=9) { <$fh>; }

#       Withdrawal elevations
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$nwd; $j+=9) { <$fh>; }

#       Withdrawal top layers
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$nwd; $j+=9) { <$fh>; }

#       Withdrawal bottom layers
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$nwd; $j+=9) { <$fh>; }

#       Tributary placement
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$ntr; $j+=9) { <$fh>; }

#       Tributary interpolation
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$ntr; $j+=9) { <$fh>; }

#       Tributary segments
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$ntr; $j+=9) { <$fh>; }

#       Tributary top elevations
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$ntr; $j+=9) { <$fh>; }

#       Tributary bottom elevations
        <$fh>; <$fh>; <$fh>; for ($j=10; $j<=$ntr; $j+=9) { <$fh>; }

#       Distributed tributary on/off
        <$fh>; <$fh>; for ($j=1; $j<=$nbr; $j++) { <$fh>; }

#       Hydraulic parameter print status
        <$fh>; <$fh>;
        for ($i=1; $i<=15; $i++) {
            for ($j=1; $j<=$nwb; $j+=9) { <$fh>; }
        }

#       Snapshot print
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            $line = <$fh>;
            $tmp1[$j] = substr($line,16,8) +0;
            $tmp2[$j] = substr($line,24,8) +0;
        }

#       Snapshot dates
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp1[$j]; $i+=9) { <$fh>; }
        }

#       Snapshot frequency
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp1[$j]; $i+=9) { <$fh>; }
        }

#       Snapshot segments
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp2[$j]; $i+=9) { <$fh>; }
        }

#       Screen print
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            $line = <$fh>;
            $tmp1[$j] = substr($line,16,8) +0;
        }

#       Screen dates
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp1[$j]; $i+=9) { <$fh>; }
        }

#       Screen frequency
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp1[$j]; $i+=9) { <$fh>; }
        }

#       Profile plot output
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            $line = <$fh>;
            $tmp1[$j] = substr($line,16,8) +0;
            $tmp2[$j] = substr($line,24,8) +0;
        }

#       Profile dates
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp1[$j]; $i+=9) { <$fh>; }
        }

#       Profile frequency
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp1[$j]; $i+=9) { <$fh>; }
        }

#       Profile segments
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp2[$j]; $i+=9) { <$fh>; }
        }

#       Spreadsheet plot output
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            $line = <$fh>;
            $nspr[$j] = &round_to_int(substr($line,16,8));
            $tmp2[$j] = substr($line,24,8) +0;
        }

#       Spreadsheet dates
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            if ($nspr[$j] == 0) {
                <$fh>;
            } else {
                for ($i=0; $i<$nspr[$j]; $i+=9) {
                    $line = <$fh>;
                    for ($n=1; $n<=9; $n++) {
                        $nn = $i +$n;
                        $sprd[$nn][$j] = substr($line,8*$n,8) +0;
                        last if ($nn >= $nspr[$j]);
                    }
                }
            }
        }

#       Spreadsheet frequency
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            if ($nspr[$j] == 0) {
                <$fh>;
            } else {
                for ($i=0; $i<$nspr[$j]; $i+=9) {
                    $line = <$fh>;
                    for ($n=1; $n<=9; $n++) {
                        $nn = $i +$n;
                        $sprf[$nn][$j] = substr($line,8*$n,8) +0;
                        last if ($nn >= $nspr[$j]);
                    }
                }
            }
        }

#       Spreadsheet segments
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp2[$j]; $i+=9) { <$fh>; }
        }

#       Vector plot output
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            $line = <$fh>;
            $tmp1[$j] = substr($line,16,8) +0;
        }

#       Vector dates
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp1[$j]; $i+=9) { <$fh>; }
        }

#       Vector frequency
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp1[$j]; $i+=9) { <$fh>; }
        }

#       Contour plot output
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            $line = <$fh>;
            $ncpl[$j] = &round_to_int(substr($line,16,8));
        }

#       Contour dates
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            if ($ncpl[$j] == 0) {
                <$fh>;
            } else {
                for ($i=0; $i<$ncpl[$j]; $i+=9) {
                    $line = <$fh>;
                    for ($n=1; $n<=9; $n++) {
                        $nn = $i +$n;
                        $cpld[$nn][$j] = substr($line,8*$n,8) +0;
                        last if ($nn >= $ncpl[$j]);
                    }
                }
            }
        }

#       Contour frequency
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            if ($ncpl[$j] == 0) {
                <$fh>;
            } else {
                for ($i=0; $i<$ncpl[$j]; $i+=9) {
                    $line = <$fh>;
                    for ($n=1; $n<=9; $n++) {
                        $nn = $i +$n;
                        $cplf[$nn][$j] = substr($line,8*$n,8) +0;
                        last if ($nn >= $ncpl[$j]);
                    }
                }
            }
        }

#       Flux output
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            $line = <$fh>;
            $tmp1[$j] = substr($line,16,8) +0;
        }

#       Flux dates
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp1[$j]; $i+=9) { <$fh>; }
        }

#       Flux frequency
        <$fh>; <$fh>;
        for ($j=1; $j<=$nwb; $j++) {
            <$fh>;
            for ($i=10; $i<=$tmp1[$j]; $i+=9) { <$fh>; }
        }

#       Time-Series plot output
        <$fh>; <$fh>;
        $line = <$fh>;
        $tmp1[1] = substr($line,16,8) +0;
        $tmp2[1] = substr($line,24,8) +0;

#       Time-Series plot dates
        <$fh>; <$fh>;
        <$fh>;
        for ($i=10; $i<=$tmp1[1]; $i+=9) { <$fh>; }

#       Time-Series plot frequency
        <$fh>; <$fh>;
        <$fh>;
        for ($i=10; $i<=$tmp1[1]; $i+=9) { <$fh>; }

#       Time-Series segments
        <$fh>; <$fh>;
        <$fh>;
        for ($i=10; $i<=$tmp2[1]; $i+=9) { <$fh>; }

#       Time-Series layers or depths
        <$fh>; <$fh>;
        <$fh>;
        for ($i=10; $i<=$tmp2[1]; $i+=9) { <$fh>; }

#       Outflow output
        <$fh>; <$fh>;
        $line = <$fh>;
        $tmp  = &round_to_int(substr($line,16,8));

#       Outflow dates
        <$fh>; <$fh>;
        if ($tmp == 0) {
            <$fh>;
        } else {
            for ($i=0; $i<$tmp; $i+=9) {
                $line = <$fh>;
                for ($n=1; $n<=9; $n++) {
                    $nn = $i +$n;
                    $wdod[$nn] = substr($line,8*$n,8) +0;
                    last if ($nn >= $tmp);
                }
            }
        }

#       Outflow frequency
        <$fh>; <$fh>;
        if ($tmp == 0) {
            <$fh>;
        } else {
            for ($i=0; $i<$tmp; $i+=9) {
                $line = <$fh>;
                for ($n=1; $n<=9; $n++) {
                    $nn = $i +$n;
                    $wdof[$nn] = substr($line,8*$n,8) +0;
                    last if ($nn >= $tmp);
                }
            }
        }


#       Skip the rest for now...
    }

#   Close the control file.
    close ($fh)
        or &pop_up_info($parent, "Unable to close control file:\n$confile");

#   Use UHS and DHS to figure out how branches connect to one another.
#   If UHS or DHS doesn't provide sufficient information, try to connect branches
#   using information from pipes, gates, spillways, and pumps.
    $iup[1] = $idn[1] = 0;
    if ($nbr > 1) {
        for ($j=1; $j<=$nbr; $j++) {
            @iup_list = @idn_list = ();
            push (@iup_list, abs($uhs[$j]));
            push (@idn_list, abs($dhs[$j]));
            for ($n=1; $n<=$nsp; $n++) {
                if ($iusp[$n] == $ds[$j] && $idsp[$n] != 0
                                         && &list_match($idsp[$n], @idn_list) == -1) {
                    shift @idn_list if ($idn_list[0] == 0);
                    push (@idn_list, $idsp[$n]);
                }
                if ($idsp[$n] == $us[$j] && $iusp[$n] != 0
                                         && &list_match($iusp[$n], @iup_list) == -1) {
                    shift @iup_list if ($iup_list[0] == 0);
                    push (@iup_list, $iusp[$n]);
                }
            }
            for ($n=1; $n<=$ngt; $n++) {
                if ($iugt[$n] == $ds[$j] && $idgt[$n] != 0
                                         && &list_match($idgt[$n], @idn_list) == -1) {
                    shift @idn_list if ($idn_list[0] == 0);
                    push (@idn_list, $idgt[$n]);
                }
                if ($idgt[$n] == $us[$j] && $iugt[$n] != 0
                                         && &list_match($iugt[$n], @iup_list) == -1) {
                    shift @iup_list if ($iup_list[0] == 0);
                    push (@iup_list, $iugt[$n]);
                }
            }
            for ($n=1; $n<=$npi; $n++) {
                if ($iupi[$n] == $ds[$j] && $idpi[$n] != 0
                                         && &list_match($idpi[$n], @idn_list) == -1) {
                    shift @idn_list if ($idn_list[0] == 0);
                    push (@idn_list, $idpi[$n]);
                }
                if ($idpi[$n] == $us[$j] && $iupi[$n] != 0
                                         && &list_match($iupi[$n], @iup_list) == -1) {
                    shift @iup_list if ($iup_list[0] == 0);
                    push (@iup_list, $iupi[$n]);
                }
            }
            for ($n=1; $n<=$npu; $n++) {
                if ($iupu[$n] == $ds[$j] && $idpu[$n] != 0
                                         && &list_match($idpu[$n], @idn_list) == -1) {
                    shift @idn_list if ($idn_list[0] == 0);
                    push (@idn_list, $idpu[$n]);
                }
                if ($idpu[$n] == $us[$j] && $iupu[$n] != 0
                                         && &list_match($iupu[$n], @iup_list) == -1) {
                    shift @iup_list if ($iup_list[0] == 0);
                    push (@iup_list, $iupu[$n]);
                }
            }
            $iup[$j] = $iup_list[0];
            for ($n=1; $n<=$#iup_list; $n++) {
                $iup[$j] .= "," . $iup_list[$n];
            }
            $idn[$j] = $idn_list[0];
            for ($n=1; $n<=$#idn_list; $n++) {
                $idn[$j] .= "," . $idn_list[$n];
            }
        }
    }

#   Populate the grid hash
    $grid{$id}{nwb} = $nwb;
    $grid{$id}{nbr} = $nbr;
    $grid{$id}{imx} = $imx;
    $grid{$id}{kmx} = $kmx;

    $grid{$id}{byear} = $byear;

    $grid{$id}{us}    = [ @us    ];
    $grid{$id}{ds}    = [ @ds    ];
    $grid{$id}{uhs}   = [ @uhs   ];
    $grid{$id}{dhs}   = [ @dhs   ];
    $grid{$id}{slope} = [ @slope ];
    $grid{$id}{elbot} = [ @elbot ];
    $grid{$id}{bs}    = [ @bs    ];
    $grid{$id}{be}    = [ @be    ];
    $grid{$id}{jbdn}  = [ @jbdn  ];

    $grid{$id}{iup}   = [ @iup ];
    $grid{$id}{idn}   = [ @idn ];

    $grid{$id}{nstr}  = [ @nstr  ];
    $grid{$id}{estrt} = [ @estrt ];
    $grid{$id}{kbswt} = [ @kbswt ];
    $grid{$id}{ktswt} = [ @ktswt ];
    $grid{$id}{sinkc} = [ @sinkc ];
    $grid{$id}{wstrt} = [ @wstrt ];

    $grid{$id}{nspr}  = [ @nspr ];
    $grid{$id}{sprd}  = [ @sprd ];
    $grid{$id}{sprf}  = [ @sprf ];

    $grid{$id}{ncpl}  = [ @ncpl ];
    $grid{$id}{cpld}  = [ @cpld ];
    $grid{$id}{cplf}  = [ @cplf ];

    $grid{$id}{wdod}  = [ @wdod ];
    $grid{$id}{wdof}  = [ @wdof ];

    return;
}


############################################################################
#
# Each bathymetry file contains bathymetric specifications for an entire
# waterbody, which can contain a series of branches.
#
# Data are added to several arrays stored in the grid hash:
#  $grid{$obj_id}{dlx}  = [ @dlx  ], $dlx[$i]    is segment length, m.
#  $grid{$obj_id}{elws} = [ @elws ], $elws[$i]   is init. water-surface elev., m.
#  $grid{$obj_id}{phi0} = [ @phi0 ], $phi0[$i]   is orientation angle, radians (0 = north)
#  $grid{$obj_id}{h}    = [ @h    ], $h[$k][$jw] is height of layer k in waterbody jw, m.
#  $grid{$obj_id}{b}    = [ @b    ], $b[$k][$i]  is width of cell in layer k and segment i, m.
#  $grid{$obj_id}{kb}   = [ @kb   ], $kb[$i]     is bottom-most active layer, segment i
#
sub read_bth {
    my ($parent, $obj_id, $jw, $bthfn) = @_;
    my (
        $aid, $fh, $i, $id, $iu, $j, $k, $kmx, $line, $new_fmt,
        @b, @be, @bs, @dlx, @ds, @elws, @h, @kb, @phi0, @us, @vals,
       );

#   Open the bathymetry file:
    open ($fh, $bthfn) or
        return &pop_up_error($parent, "Unable to open bathymetry file:\n$bthfn");

#   Determine whether file is original format or new format
    $line = <$fh>;
    $new_fmt = (substr($line,0,1) eq "\$") ? 1 : 0;

    @dlx = @elws = @phi0 = @h = @b = @kb = ();
    if (defined($grid{$obj_id}{dlx})) {
        @dlx  = @{ $grid{$obj_id}{dlx}  };
        @elws = @{ $grid{$obj_id}{elws} };
        @phi0 = @{ $grid{$obj_id}{phi0} };
        @h    = @{ $grid{$obj_id}{h}    };
        @b    = @{ $grid{$obj_id}{b}    };
        @kb   = @{ $grid{$obj_id}{kb}   };
    }
    $kmx = $grid{$obj_id}{kmx};
    @bs  = @{ $grid{$obj_id}{bs} };
    @be  = @{ $grid{$obj_id}{be} };
    @us  = @{ $grid{$obj_id}{us} };
    @ds  = @{ $grid{$obj_id}{ds} };
    $iu  = $us[$bs[$jw]];
    $id  = $ds[$be[$jw]];

#   New format
    if ($new_fmt) {

#       First line should be segment numbers, but model doesn't read them
        $line = <$fh>;
        chomp $line;
        $line =~ s/,+$//;
        ($aid, @vals) = split(/,/, $line);
        if ($aid !~ /SEG/i || $vals[0] != $iu-1) {
            &pop_up_info($parent, "Check segment numbers (SEG) in bathymetry file:\n$bthfn");
        }

#       Read the segment lengths
        $line = <$fh>;
        chomp $line;
        $line =~ s/,+$//;
        ($aid, @vals) = split(/,/, $line);
        if ($aid !~ /DLX/i || $#vals != $id+1-($iu-1)) {
            return &pop_up_error($parent, "Check segment lengths (DLX) in bathymetry file:\n$bthfn");
        }
        for ($i=$iu-1; $i<=$id+1; $i++) {
            $dlx[$i] = $vals[$i-($iu-1)];
        }

#       Read the initial water-surface elevations
        $line = <$fh>;
        chomp $line;
        $line =~ s/,+$//;
        ($aid, @vals) = split(/,/, $line);
        if ($aid !~ /ELWS/i || $#vals != $id+1-($iu-1)) {
            return &pop_up_error($parent, "Check water-surface elevations (ELWS) in bathymetry file:\n$bthfn");
        }
        for ($i=$iu-1; $i<=$id+1; $i++) {
            $elws[$i] = $vals[$i-($iu-1)];
        }

#       Read segment orientations
        $line = <$fh>;
        chomp $line;
        $line =~ s/,+$//;
        ($aid, @vals) = split(/,/, $line);
        if ($aid !~ /PHI[0O]/i || $#vals != $id+1-($iu-1)) {
            return &pop_up_error($parent, "Check segment orientations (PHI0) in bathymetry file:\n$bthfn");
        }
        for ($i=$iu-1; $i<=$id+1; $i++) {
            $phi0[$i] = $vals[$i-($iu-1)];
        }

#       Skip the friction coefficients
        <$fh>;

#       Next are the layer heights and cell widths
        <$fh>;
        for ($k=1; $k<=$kmx; $k++) {
            $line = <$fh>;
            chomp $line;
            $line =~ s/,+$//;
            ($h[$k][$jw], @vals) = split(/,/, $line);
            for ($i=$iu-1; $i<=$id+1; $i++) {
                $b[$k][$i] = $vals[$i-($iu-1)];
            }
        }

#   Original format
    } else {

#       Read the segment lengths
        <$fh>; <$fh>;
        for ($i=$iu-1; $i<=$id+1; $i+=10) {
            $line = <$fh>;
            for ($j=0; $j<10; $j++) {
                last if ($i +$j > $id +1);
                $dlx[$i+$j] = substr($line,$j*8,8);
            }
        }

#       Read the initial water-surface elevations
        <$fh>; <$fh>;
        for ($i=$iu-1; $i<=$id+1; $i+=10) {
            $line = <$fh>;
            for ($j=0; $j<10; $j++) {
                last if ($i +$j > $id +1);
                $elws[$i+$j] = substr($line,$j*8,8);
            }
        }

#       Next are the orientation angles
        <$fh>; <$fh>;
        for ($i=$iu-1; $i<=$id+1; $i+=10) {
            $line = <$fh>;
            for ($j=0; $j<10; $j++) {
                last if ($i +$j > $id +1);
                $phi0[$i+$j] = substr($line,$j*8,8);
            }
        }

#       Skip the friction factors
        <$fh>; <$fh>; for ($i=$iu-1; $i<=$id+1; $i+=10) { $line = <$fh>; }

#       Read the layer heights
        <$fh>; <$fh>;
        for ($k=1; $k<=$kmx; $k+=10) {
            $line = <$fh>;
            for ($j=0; $j<10; $j++) {
                last if ($k +$j > $kmx);
                $h[$k+$j][$jw] = substr($line,$j*8,8);
            }
        }

#       Finally, read the cell widths for each segment
        for ($i=$iu-1; $i<=$id+1; $i++) {
            <$fh>; <$fh>;
            for ($k=1; $k<=$kmx; $k+=10) {
                $line = <$fh>;
                for ($j=0; $j<10; $j++) {
                    last if ($k +$j > $kmx);
                    $b[$k+$j][$i] = substr($line,$j*8,8);
                }
            }
        }
    }

#   Close the bathymetry file.
    close ($fh)
        or &pop_up_info($parent, "Unable to close bathymetry file:\n$bthfn");

#   Calculate the bottom-most active cell in each segment.
    for ($i=$iu-1; $i<=$id+1; $i++) {
        for ($k=2; $k<=$kmx; $k++) {
            last if ($b[$k][$i] == 0);
            $kb[$i] = $k;
        }
    }

#   Store the new or updated arrays in the grid hash
    $grid{$obj_id}{dlx}  = [ @dlx  ];
    $grid{$obj_id}{elws} = [ @elws ];
    $grid{$obj_id}{phi0} = [ @phi0 ];
    $grid{$obj_id}{h}    = [ @h    ];
    $grid{$obj_id}{b}    = [ @b    ];
    $grid{$obj_id}{kb}   = [ @kb   ];

    return;
}


############################################################################
#
# Read just some selected information from a W2 bathymetry file
#
# Data to read:
#  cell widths from one particular segment number
#  bottom-most active cell in that segment
#  number of layers
#  layer heights
#
sub read_bth_slice {
    my ($parent, $seg, $bthfn) = @_;
    my (
        $fh, $i, $j, $k, $kb, $keep_going, $kmx, $line, $new_fmt, $ns,
        $val_index,
        @b, @h, @vals,
        );

#   Open the bathymetry file
    open ($fh, $bthfn) or
        return &pop_up_error($parent, "Unable to open bathymetry file:\n$bthfn");

#   Determine whether file is original format or new format
    $line = <$fh>;
    $new_fmt = (substr($line,0,1) eq "\$") ? 1 : 0;

#   Initialize arrays
    @h = @b = ();

#   New format
    if ($new_fmt) {

#       First line should be segment numbers
#       W2 doesn't read these, but we need them
        $line = <$fh>;
        chomp $line;
        $line =~ s/,+$//;
        (undef, @vals) = split(/,/, $line);
        $val_index = -99;
        for ($i=0; $i<=$#vals; $i++) {
            if ($vals[$i] == $seg) {
                $val_index = $i;
                last;
            }
        }
        if ($val_index == -99) {
            return &pop_up_error($parent, "Segment number $seg not found in bathymetry file:\n$bthfn");
        }

#       Skip the segment lengths
        <$fh>;

#       Skip the initial water-surface elevations
        <$fh>;

#       Skip the segment orientations
        <$fh>;

#       Skip the friction coefficients
        <$fh>;

#       Next are the layer heights and cell widths
        <$fh>;
        $k = 0;
        while (defined( $line = <$fh> )) {
            chomp $line;
            $line =~ s/,+$//;
            next if ($line eq "");
            $k++;
            ($h[$k], @vals) = split(/,/, $line);
            $b[$k] = $vals[$val_index];
        }
        $kmx = $k;

#   Original format
    } else {

#       Skip the segment lengths but count the segments
        <$fh>; <$fh>;
        $ns = 0;
        $keep_going = 1;
        while ($keep_going) {
            $line = <$fh>;
            $line = substr($line,0,80) if (length($line) > 80);
            for ($j=0; $j<10; $j++) {
                if (length($line) <= $j*8) {
                    $keep_going = 0;
                    last;
                }
                if (substr($line,$j*8,8) !~ /[0-9.]+/) {
                    $keep_going = 0;
                    last;
                }
                $ns++;
            }
        }

#       Skip the initial water-surface elevations
        <$fh>; <$fh>; for ($i=1; $i<=$ns; $i+=10) { <$fh>; }

#       Skip the orientation angles
        <$fh>; <$fh>; for ($i=1; $i<=$ns; $i+=10) { <$fh>; }

#       Skip the friction factors
        <$fh>; <$fh>; for ($i=1; $i<=$ns; $i+=10) { <$fh>; }

#       Read the layer heights
        <$fh>; <$fh>;
        $k = 0;
        $keep_going = 1;
        while ($keep_going) {
            $line = <$fh>;
            $line = substr($line,0,80) if (length($line) > 80);
            for ($j=0; $j<10; $j++) {
                if (length($line) <= $j*8) {
                    $keep_going = 0;
                    last;
                }
                if (substr($line,$j*8,8) !~ /[0-9.]+/) {
                    $keep_going = 0;
                    last;
                }
                $k++;
                $h[$k] = substr($line,$j*8,8);
            }
        }
        $kmx = $k;

#       Finally, read the cell widths for each segment
        for ($i=1; $i<=$ns; $i++) {
            <$fh>; $line = <$fh>;
            if ($line =~ /segment\s+.*${seg}\s*$/i) {
                for ($k=1; $k<=$kmx; $k+=10) {
                    $line = <$fh>;
                    for ($j=0; $j<10; $j++) {
                        last if ($k +$j > $kmx);
                        $b[$k+$j] = substr($line,$j*8,8);
                    }
                }
                last;
            } elsif ($i == $seg) {
                for ($k=1; $k<=$kmx; $k+=10) {
                    $line = <$fh>;
                    for ($j=0; $j<10; $j++) {
                        last if ($k +$j > $kmx);
                        $b[$k+$j] = substr($line,$j*8,8);
                    }
                }
            } else {
                for ($k=1; $k<=$kmx; $k+=10) {
                    $line = <$fh>;
                }
            }
        }
        if ($#b < 0) {
            return &pop_up_error($parent, "Segment number $seg not found in bathymetry file:\n$bthfn");
        }
    }

#   Close the bathymetry file.
    close ($fh)
        or &pop_up_info($parent, "Unable to close bathymetry file:\n$bthfn");

#   Calculate the bottom-most active cell in the target segment.
    for ($k=2; $k<=$kmx; $k++) {
        last if ($b[$k] == 0);
        $kb = $k;
    }

    return ($kmx, $kb, \@h, \@b);
}


############################################################################
#
# Calculate elevations of layer tops for every segment in waterbody JW
# of the model grid.
#
# This routine is called only after the control file (read_con) and the
# appropriate bathymetric input file (read_bth) have been read.
#
# Portions of code were translated into Perl from the CE-QUAL-W2 source.
#
# Variable added to grid hash for segments in waterbody JW:
#  $grid{$id}{el} = [ @el ], $el[$k][$i] is elevation of top of layer k, segment i
#
sub get_grid_elevations {
    my ($parent, $id, $jw) = @_;
    my (
        $i, $jb, $jjb, $k, $kmx, $nbr, $ninternal, $nnbp, $nup, $zero_slope,

        @be, @bs, @cosa, @dhs, @dlx, @dn_head, @ds, @el, @elbot, @h, @jbdn,
        @npoint, @sina, @slope, @uhs, @up_head, @us,
       );

    @el = @sina = @cosa = @npoint = @dn_head = @up_head = ();

#   Retrieve control-file variables from the grid hash
    if (! defined($grid{$id})
                || ! defined($grid{$id}{nbr})   || ! defined($grid{$id}{kmx})
                || ! defined($grid{$id}{bs})    || ! defined($grid{$id}{be})
                || ! defined($grid{$id}{us})    || ! defined($grid{$id}{ds})
                || ! defined($grid{$id}{uhs})   || ! defined($grid{$id}{dhs})
                || ! defined($grid{$id}{jbdn})  || ! defined($grid{$id}{elbot})
                || ! defined($grid{$id}{slope})) {
        return &pop_up_error($parent, "Cannot compute grid geometry\n"
                                    . "until W2 control file is read.");
    }
    $nbr   = $grid{$id}{nbr};
    $kmx   = $grid{$id}{kmx};
    @bs    = @{ $grid{$id}{bs}    };
    @be    = @{ $grid{$id}{be}    };
    @us    = @{ $grid{$id}{us}    };
    @ds    = @{ $grid{$id}{ds}    };
    @uhs   = @{ $grid{$id}{uhs}   };
    @dhs   = @{ $grid{$id}{dhs}   };
    @jbdn  = @{ $grid{$id}{jbdn}  };
    @elbot = @{ $grid{$id}{elbot} };
    @slope = @{ $grid{$id}{slope} };

#   Retrieve bathymetric-file variables from the grid hash
    if (! defined($grid{$id}{h}) || ! defined($grid{$id}{dlx})) {
        return &pop_up_error($parent, "Cannot compute grid geometry until\n"
                                    . "W2 bathymetry or contour file is read.");
    }
    @h   = @{ $grid{$id}{h}   };
    @dlx = @{ $grid{$id}{dlx} };

#   Load the elevation array, if part has already been generated
    @el = @{ $grid{$id}{el} } if (defined($grid{$id}{el}));

#   Set some values that are used later
    for ($jb=$bs[$jw]; $jb<=$be[$jw]; $jb++) {
        $sina[$jb]   = sin( atan2($slope[$jb], 1) );
        $cosa[$jb]   = cos( atan2($slope[$jb], 1) );
        $npoint[$jb] = 0;
    }

#   Set some branch connection flags
    for ($jb=1; $jb<=$nbr; $jb++) {
        $up_head[$jb] = ($uhs[$jb] != 0) ? 1 : 0;
        if ($up_head[$jb]) {
            for ($jjb=1; $jjb<=$nbr; $jjb++) {
                if (abs($uhs[$jb]) >= $us[$jjb] && abs($uhs[$jb]) <= $ds[$jjb]) {
                    if (abs($uhs[$jb]) == $ds[$jjb]) {
                        if ($dhs[$jjb] == $us[$jb]) {
                            $up_head[$jb] = 0;
                        }
                        if ($uhs[$jb] < 0) {
                            $up_head[$jb] = 0;
                            $uhs[$jb]     = abs($uhs[$jb]);
                        }
                    }
                    last;
                }
            }
        }
        $dn_head[$jb] = ($dhs[$jb] != 0) ? 1 : 0;
    }

#   Determine whether the grid is flat in a particular waterbody
    $zero_slope = 1;
    for ($jb=$bs[$jw]; $jb<=$be[$jw]; $jb++) {
        if ($slope[$jb] != 0.0) {
            $zero_slope = 0;
            last;
        }
    }

#   If slope is zero, the calculations are easy
    if ($zero_slope) {
        for ($i=$us[$bs[$jw]]-1; $i<=$ds[$be[$jw]]+1; $i++) {
            $el[$kmx][$i] = $elbot[$jw];
            for ($k=$kmx-1; $k>=1; $k--) {
                $el[$k][$i] = $el[$k+1][$i] +$h[$k][$jw];
            }
        }

#   For nonzero slopes, follow the segments upstream
    } else {
        $el[$kmx][$ds[$jbdn[$jw]]+1] = $elbot[$jw];
        $jb          = $jbdn[$jw];
        $npoint[$jb] = 1;
        $nnbp        = 1;
        $ninternal   = 0;
        $nup         = 0;
        while ($nnbp <= $be[$jw] -$bs[$jw] +1) {
            if ($ninternal == 0) {
                if ($nup == 0) {
                    for ($i=$ds[$jb]; $i>=$us[$jb]; $i--) {
                        $el[$kmx][$i] = $el[$kmx][$i+1];
                        if ($i != $ds[$jb]) {
                            $el[$kmx][$i] += $sina[$jb] *($dlx[$i] +$dlx[$i+1])*0.5;
                        }
                        for ($k=$kmx-1; $k>=1; $k--) {
                            $el[$k][$i] = $el[$k+1][$i] +$h[$k][$jw] *$cosa[$jb];
                        }
                    }
                } else {
                    for ($i=$us[$jb]; $i<=$ds[$jb]; $i++) {
                        $el[$kmx][$i] = $el[$kmx][$i-1];
                        if ($i != $us[$jb]) {
                            $el[$kmx][$i] -= $sina[$jb] *($dlx[$i] +$dlx[$i-1])*0.5;
                        }
                        for ($k=$kmx-1; $k>=1; $k--) {
                            $el[$k][$i] = $el[$k+1][$i] +$h[$k][$jw] *$cosa[$jb];
                        }
                    }
                    $nup = 0;
                }
                for ($k=$kmx; $k>=1; $k--) {
                    $el[$k][$us[$jb]-1] = $el[$k][$us[$jb]];
                    if ($up_head[$jb]) {
                        $el[$k][$us[$jb]-1] += $sina[$jb] *$dlx[$us[$jb]];
                    }
                    $el[$k][$ds[$jb]+1] = $el[$k][$ds[$jb]];
                    if ($dn_head[$jb]) {
                        $el[$k][$ds[$jb]+1] -= $sina[$jb] *$dlx[$ds[$jb]];
                    }
                }
            } else {
                for ($k=$kmx-1; $k>=1; $k--) {
                    $el[$k][$uhs[$jjb]] = $el[$k+1][$uhs[$jjb]] +$h[$k][$jw] *$cosa[$jb];
                }
                for ($i=$uhs[$jjb]+1; $i<=$ds[$jb]; $i++) {
                    $el[$kmx][$i] = $el[$kmx][$i-1] -$sina[$jb] *($dlx[$i] +$dlx[$i-1])*0.5;
                    for ($k=$kmx-1; $k>=1; $k--) {
                        $el[$k][$i] = $el[$k+1][$i] +$h[$k][$jw] *$cosa[$jb];
                    }
                }
                for ($i=$uhs[$jjb]-1; $i>=$us[$jb]; $i--) {
                    $el[$kmx][$i] = $el[$kmx][$i+1] +$sina[$jb] *($dlx[$i] +$dlx[$i+1])*0.5;
                    for ($k=$kmx-1; $k>=1; $k--) {
                        $el[$k][$i] = $el[$k+1][$i] +$h[$k][$jw] *$cosa[$jb];
                    }
                }
                $ninternal = 0;
            }
            last if ($nnbp == $be[$jw] -$bs[$jw] +1);

#           Find next branch connected to furthest downstream branch
            for ($jb=$bs[$jw]; $jb<=$be[$jw]; $jb++) {
                if ($npoint[$jb] != 1) {
                    for ($jjb=$bs[$jw]; $jjb<=$be[$jw]; $jjb++) {
                        if ($dhs[$jb] >= $us[$jjb] && $dhs[$jb] <= $ds[$jjb] && $npoint[$jjb] == 1) {
                            $npoint[$jb] = 1;
                            $el[$kmx][$ds[$jb]+1] = $el[$kmx][$dhs[$jb]]
                                                   +$sina[$jb] *($dlx[$ds[$jb]] +$dlx[$dhs[$jb]])*0.5;
                            $nnbp++;
                            last;
                        }
                        if ($uhs[$jjb] == $ds[$jb] && $npoint[$jjb] == 1) {
                            $npoint[$jb] = 1;
                            $el[$kmx][$ds[$jb]+1] = $el[$kmx][$us[$jjb]]
                                                  +($sina[$jjb] *$dlx[$us[$jjb]]
                                                   +$sina[$jb]  *$dlx[$ds[$jb]])*0.5;
                            $nnbp++;
                            last;
                        }
                        if ($uhs[$jjb] >= $us[$jb] && $uhs[$jjb] <= $ds[$jb] && $npoint[$jjb] == 1) {
                            $npoint[$jb] = 1;
                            $ninternal   = 1;
                            $el[$kmx][$uhs[$jjb]] = $el[$kmx][$us[$jjb]]
                                                   +$sina[$jjb] *$dlx[$us[$jjb]]*0.5;
                            $nnbp++;
                            last;
                        }
                        if ($uhs[$jb] >= $us[$jjb] && $uhs[$jb] <= $ds[$jjb] && $npoint[$jjb] == 1) {
                            $npoint[$jb] = 1;
                            $nup         = 1;
                            $el[$kmx][$us[$jb]-1] = $el[$kmx][$uhs[$jb]]
                                                   -$sina[$jb] *$dlx[$us[$jb]]*0.5;
                            $nnbp++;
                            last;
                        }
                    }
                    last if ($npoint[$jb] == 1);
                }
            }
        }
    }
    $grid{$id}{el} = [ @el ];
    return;
}


############################################################################
#
# Subroutine to read a CE-QUAL-W2 meteorological input file.
#
sub read_w2_met_file {
    my ($parent, $file, $parm) = @_;
    my (
        $comma_delimited, $fh, $field, $jd, $line,
        @fields,
        %ts_data,
       );

    if (! defined($parm) || lc($parm) !~ /^(tair|tdew|wind|wdir|cloud|solar)$/) {
        return &pop_up_error($parent, "Invalid parameter for W2 meteorological input file");
    }

    @fields  = qw(jday tair tdew wind wdir cloud solar);
    $field   = &list_match(lc($parm), @fields);
    %ts_data = ();

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 meteorological input file:\n$file");

#   Read the file
    $line = <$fh>;
    $comma_delimited = (substr($line,0,1) eq '$') ? 1 : 0;
    $line = <$fh>;
    $line = <$fh>;
    if ($comma_delimited) {
        while (defined( $line = <$fh> )) {
            chomp $line;
            @fields = split(/,/, $line);
            $ts_data{$fields[0]} = $fields[$field];
        }
    } else {
        while (defined( $line = <$fh> )) {
            chomp $line;
            $jd = substr($line,0,8);
            $ts_data{$jd} = substr($line,8*$field,8);
        }
    }

#   Close the file.
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 meteorological input file:\n$file");

    return %ts_data;
}


############################################################################
#
# Subroutine to read a CE-QUAL-W2 time-series file.
#
# The following file types can be read:
#  "W2 TSR format"
#  "W2 Outflow CSV format"
#  "W2 Layer Outflow CSV format"
#  "W2 CSV format"
#  "W2 column format"
#
# The first field is expected to be a W2-type JDAY, which will be converted
# into a date for W2Anim using the supplied begin year.
#
# Returns a hash where the date keys to the data, and the date is in
# YYYYMMDDHHmm format.
#
sub read_w2_timeseries {
    my ($parent, $file, $file_type, $parm, $byear, $pbar) = @_;
    my (
        $begin_jd, $dt, $fh, $i, $jd, $line, $missing, $next_nl, $nl,
        $progress_bar, $val, $value_field,

        @fields, @parms,
        %ts_data,
       );

    $nl = 0;
    $next_nl = 250;
    $missing = "na";
    $progress_bar = ($pbar ne "") ? 1 : 0;

    $begin_jd = &date2jdate(sprintf("%04d%02d%02d", $byear, 1, 1));
    @fields   = ();
    %ts_data  = ();

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 time-series file:\n$file");

#   Read the file
    if ($file_type eq "W2 TSR format") {
        $line = <$fh>;
        if ($line !~ /^JDAY,DLT\(s\),ELWS\(m\),T2\(C\),U/) {
            return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
        }
        @parms = split(/,/, substr($line,5));
        for ($i=0; $i<=$#parms; $i++) {
            $parms[$i] =~ s/^\s+//;
            $parms[$i] =~ s/\s+$//;
        }
        $value_field = &list_match($parm, @parms);
        if ($value_field == -1) {
            return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
        }
        $line = <$fh>;
        $line = <$fh>;
        while (defined($line = <$fh>)) {
            chomp $line;
            ($jd, @fields) = split(/,/, $line);
            $dt = &jdate2date($jd + $begin_jd -1);
            $ts_data{$dt} = $fields[$value_field];

            $nl++;
            if ($progress_bar && $nl >= $next_nl) {
                $next_nl += 250;
                &update_progress_bar($pbar, $nl);
            }
        }

    } elsif ($file_type eq "W2 Outflow CSV format") {
        $line = <$fh>;
        if ($line !~ /^\$Flow file for segment / &&
            $line !~ /^\$Temperature file for segment / &&
            $line !~ /^\$Concentration file for segment / &&
            $line !~ /^Derived constituent file for segment / &&
            $line !~ /^\$STR WITHDRAWAL AT SEG/) {
            return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
        }
        if ($line =~ /^\$Concentration/ || $line =~ /^Derived/ || $line =~ /^\$STR WITHDRAWAL/) {
            $line = <$fh>;
            $line = <$fh>;   # check headers on third line
            chomp $line;
            $line  =~ s/,+$//;
            @parms = split(/,/, substr($line,5));
            for ($i=0; $i<=$#parms; $i++) {
                $parms[$i] =~ s/^\s+//;
                $parms[$i] =~ s/\s+$//;
            }
            $value_field = &list_match($parm, @parms);
            if ($value_field == -1) {
                return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
            }
        } else {
            if ($line =~ /^\$Flow/) {
                ($value_field = $parm) =~ s/^Flow(\d+)$/$1/;
            } else {
                ($value_field = $parm) =~ s/^Temperature(\d+)$/$1/;
            }
            $value_field--;
            if ($value_field < 0) {
                return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
            }
            $line = <$fh>;
            $line = <$fh>;
        }
        while (defined($line = <$fh>)) {
            chomp $line;
            ($jd, @fields) = split(/,/, $line);
            $dt  = &jdate2date($jd + $begin_jd -1);
            $val = $fields[$value_field];
            if (defined($val) && $val != -99.) {
                $ts_data{$dt} = $val;
            } else {
                $ts_data{$dt} = $missing;
            }

            $nl++;
            if ($progress_bar && $nl >= $next_nl) {
                $next_nl += 250;
                &update_progress_bar($pbar, $nl);
            }
        }

    } elsif ($file_type eq "W2 Layer Outflow CSV format") {
        $line = <$fh>;
        if ($line !~ /^Flow layers file for segment /) {
            return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
        }
        $line = <$fh>;
        if ($line !~ /^Output is JDAY, total outflow, WS elev, and layer outflows starting /) {
            return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
        }
        if ($parm =~ /Total Outflow, segment/) {
            $value_field = 0;
        } elsif ($parm =~ /WS Elevation, segment/) {
            $value_field = 1;
        } else {
            return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
        }
        $line = <$fh>;
        while (defined($line = <$fh>)) {
            chomp $line;
            ($jd, @fields) = split(/,/, $line);
            $dt = &jdate2date($jd + $begin_jd -1);
            $ts_data{$dt} = $fields[$value_field];

            $nl++;
            if ($progress_bar && $nl >= $next_nl) {
                $next_nl += 250;
                &update_progress_bar($pbar, $nl);
            }
        }

    } elsif ($file_type eq "W2 CSV format") {
        $line = <$fh>;
        if (substr($line,0,1) ne '$') {
            return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
        }
        ($value_field = $parm) =~ s/^Parameter(\d+)$/$1/;
        $value_field--;
        if ($value_field < 0) {
            return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
        }
        $line = <$fh>;
        $line = <$fh>;
        while (defined($line = <$fh>)) {
            chomp $line;
            ($jd, @fields) = split(/,/, $line);
            $dt  = &jdate2date($jd + $begin_jd -1);
            $val = $fields[$value_field];
            if (defined($val) && $val != -99.) {
                $ts_data{$dt} = $val;
            } else {
                $ts_data{$dt} = $missing;
            }

            $nl++;
            if ($progress_bar && $nl >= $next_nl) {
                $next_nl += 250;
                &update_progress_bar($pbar, $nl);
            }
        }

    } elsif ($file_type eq "W2 column format") {
        ($value_field = $parm) =~ s/^Parameter(\d+)$/$1/;
        if ($value_field < 1) {
            return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
        }
        $line = <$fh>;
        $line = <$fh>;
        $line = <$fh>;
        while (defined($line = <$fh>)) {
            chomp $line;
            $jd  = substr($line,0,8);
            $dt  = &jdate2date($jd + $begin_jd -1);
            $val = substr($line,8*$value_field,8);
            if (defined($val) && $val != -99.) {
                $ts_data{$dt} = $val;
            } else {
                $ts_data{$dt} = $missing;
            }

            $nl++;
            if ($progress_bar && $nl >= $next_nl) {
                $next_nl += 250;
                &update_progress_bar($pbar, $nl);
            }
        }

    } else {
        return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
    }

#   Close the file
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 time-series file:\n$file");

    return %ts_data;
}


############################################################################
#
# Subroutine to read a CE-QUAL-W2 Layer Outflow CSV file
#
# The first field is expected to be a W2-type JDAY, which will be converted
# into a date for W2Anim using the supplied begin year.
#
# Returns two hashes of flow and velocity where the date keys to
# the data, and the date is in YYYYMMDDHHmm format.
#
sub read_w2_layer_outflow {
    my ($parent, $id, $file, $seg, $byear, $nskip, $pbar) = @_;
    my (
        $area, $begin_jd, $dt, $first, $fh, $height, $jd, $k, $kk, $line,
        $next_nl, $nl, $progress_bar, $wsel,
        @b, @el, @flows, @veloc,
        %qdata, %vdata,
       );

    $nl = 0;
    $next_nl = 250;
    $progress_bar = ($pbar ne "") ? 1 : 0;

    $begin_jd = &date2jdate(sprintf("%04d%02d%02d", $byear, 1, 1));
    @b        = @{ $grid{$id}{b}  };
    @el       = @{ $grid{$id}{el} };
    @flows    = ();
    @veloc    = ();
    %qdata    = ();
    %vdata    = ();

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 Layer Outflow time-series file:\n$file");

#   Read the file
    $line = <$fh>;
    if ($line !~ /^Flow layers file for segment /) {
        return &pop_up_error($parent, "File is not a W2 Layer Outflow time-series file:\n$file");
    }
    $line = <$fh>;
    if ($line !~ /^Output is JDAY, total outflow, WS elev, and layer outflows starting /) {
        return &pop_up_error($parent, "File is not a W2 Layer Outflow time-series file:\n$file");
    }
    $line = <$fh>;
    while (defined($line = <$fh>)) {
        if ($nl % ($nskip+1) == 0) {
            chomp $line;
            ($jd, @flows) = split(/,/, $line);
            $dt = &jdate2date($jd + $begin_jd -1);

            @veloc = @flows;
            $wsel  = $flows[1];         # $flows[1] is WS elev (m)
            $first = 1;
            for ($k=2; $k<=$#flows; $k++) {
                next if (! defined($flows[$k]) || $flows[$k] eq "");
                if ($first) {
                    $height = $wsel -$el[$k+1][$seg];
                    $first  = 0;
                    $area   = 0;
                    for ($kk=$k; $kk>=2; $kk--) {
                        if ($wsel > $el[$kk][$seg]) {
                            $area += ($el[$kk][$seg] -$el[$kk+1][$seg]) *$b[$kk][$seg];
                        } else {
                            $area += ($wsel -$el[$kk+1][$seg]) *$b[$kk][$seg];
                            last;
                        }
                    }
                } else {
                    $height = $el[$k][$seg] -$el[$k+1][$seg];
                    $area   = $height *$b[$k][$seg];
                }
                $veloc[$k]  = $flows[$k]/$area;
                $flows[$k] /= $height;
            }
            $qdata{$dt} = [ @flows ];
            $vdata{$dt} = [ @veloc ];
        }
        $nl++;
        if ($progress_bar && $nl >= $next_nl) {
            $next_nl += 250;
            &update_progress_bar($pbar, $nl);
        }
    }

#   Close the file
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 Layer Outflow time-series file:\n$file");

    return (\%qdata, \%vdata);
}


############################################################################
#
# Subroutine to determine whether a file is a W2 Spreadsheet output file
# or a W2 Contour output file, or neither.
#
sub confirm_w2_ftype {
    my ($parent, $file) = @_;
    my ($fh, $ftype, $i, $line);

    $ftype = "na";

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open file:\n$file");

#   Check for W2 Spreadsheet output format
    $line = <$fh>;
    if ($line =~ /^Constituent,Julian_day,Depth,Elevation,Seg_/) {
        $ftype = "spr";

#   Check for W2 Contour output format (Tecplot)
    } elsif ($line =~ /^ TITLE=\"CE-QUAL-W2\"/) {
        $line = <$fh>;
        if ($line =~ /^VARIABLES=\"Distance, m\",\"Elevation, m\",\"U/) {
            $ftype = "cpl";
        }

#   Check for W2 Contour output format (original)
    } else {
        seek ($fh, 0, 0);   # push file position pointer back to beginning
        for ($i=0; $i<10; $i++) {
            $line = <$fh>;
        }
        $line = <$fh>;        # check 11th line for telltale text
        if ($line =~ /^Model run at / || $line =~ /^Model restarted at /) {
            while (defined($line = <$fh>)) {
                if ($line =~ /^New date /) {   # check for start of day's data
                    $ftype = "cpl";
                    last;
                }
            }
        }
    }

#   Close the file
    close ($fh)
        or &pop_up_info($parent, "Unable to close file:\n$file");

    return $ftype;
}


############################################################################
#
# Subroutine to scan a CE-QUAL-W2 spreadsheet output file and return
# the number of lines and references to lists of the segment numbers
# and parameters that the file contains.
# The file is assumed to be comma-delimited.
#
sub scan_w2_spr_file {
    my ($parent, $file, $pbar_img) = @_;
    my (
        $fh, $first_jd, $i, $jd, $line, $next_nl, $nf, $nl, $parm,
        @fields, @parms, @segs,
       );

    $nf = 0;
    $next_nl = 5000;
    @parms = @segs = ();

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 spreadsheet file:\n$file");

#   Read header line, check format, and determine segment numbers and order
    $line = <$fh>;
    if ($line !~ /^Constituent,Julian_day,Depth,Elevation,Seg_/) {
        return ("bad", $nl, \@segs, \@parms);
    }
    @fields = split(/,/, $line);
    for ($i=4; $i<=$#fields; $i++) {
        if ($fields[$i] =~ /Seg_/) {
            $fields[$i] =~ s/\s*Seg_(\d+)\s*/$1/;
            push (@segs, $fields[$i]);
        }
    }

#   Determine the first parameter, which is on the second line
    $line = <$fh>;
    ($parm, $jd, @fields) = split(/,/, $line);
    $parm =~ s/^\s+//;
    $parm =~ s/\s+$//;
    push (@parms, $parm);
    $first_jd = $jd;
    $nl = 1;

#   Continue reading and adding to the parm list until the next JDAY is encountered
    while ($jd == $first_jd && defined($line = <$fh>)) {
        ($parm, $jd, @fields) = split(/,/, $line);
        $parm =~ s/^\s+//;
        $parm =~ s/\s+$//;
        if (&list_match($parm, @parms) == -1) {
            push (@parms, $parm);
        }
        $nl++;
        if ($nl >= $next_nl) {
            $next_nl += 5000;
            $nf = &update_alt_progress_bar($pbar_img, $nl, $nf);
        }
    }

#   Count the rest of the lines in the file
    while (<$fh>) {
        $nl++;
        if ($nl >= $next_nl) {
            $next_nl += 5000;
            $nf = &update_alt_progress_bar($pbar_img, $nl, $nf);
        }
    }

#   Close the file
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 spreadsheet file:\n$file");

    return ("ok", $nl, \@segs, \@parms);
}


############################################################################
#
# Subroutine to read a CE-QUAL-W2 spreadsheet output file
# File is assumed to be comma-delimited.
#
# The first field of a W2 spreadsheet file is the parameter name, and the
# second field is a W2-type JDAY, which will be converted into a date for
# W2Anim using the supplied begin year.  Other fields are depths, elevations,
# and cell concentrations.
#
# The calling program provides the following:
#   parent   -- parent window of calling routine
#   id       -- graph object id associated with this file
#   file     -- W2 spreadsheet output file
#   parm     -- name of parameter of interest
#   parm_div -- parameter divisor, if necessary, or "None"
#   byear    -- begin year, where JDAY = 1.0 on Jan 1 of that year
#   segnum   -- target segment number, or 0 for all available segments
#   nskip    -- number of dates to skip (0 = none, 1 = every other, etc.)
#   pbar     -- progress bar widget handle
#
# Values for the specified parameter will be read, and optionally divided
# by the values for the parm_div parameter.
#
# Returns two hashes where the date keys to the data, and the date is in
# YYYYMMDDHHmm format.
#
sub read_w2_spr_file {
    my ($parent, $id, $file, $parm, $parm_div, $byear, $segnum, $nskip, $pbar) = @_;
    my (
        $begin_jd, $dt, $fh, $i, $jd, $last_jd, $last_jd_div, $last_jd_temp,
        $line, $n, $nd, $nd_keep, $next_nl, $nl, $nlayers, $pname,
        $seg_choice,

        @el, @fields, @kb, @nn, @segs,
        %div_data, %elev_data, %kt_data, %parm_data,
       );

    $segnum   = "all" if (! defined($segnum) || $segnum eq "");
    $begin_jd = &date2jdate(sprintf("%04d%02d%02d", $byear, 1, 1));
    $parm_div = "None" if (! defined($parm_div) || $parm_div eq "");
    
    @nn = @segs = ();
    %kt_data = %elev_data = %parm_data = %div_data = ();

#   Load kb array. Assume that bathymetry file has been read already.
    if (! defined($grid{$id}) || ! defined($grid{$id}{el}) || ! defined($grid{$id}{kb})) {
        return &pop_up_error($parent, "Cannot read W2 spreadsheet file\nuntil W2 bathymetry file is read.");
    }
    @el = @{ $grid{$id}{el} };
    @kb = @{ $grid{$id}{kb} };

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 spreadsheet file:\n$file");

#   Read the header line to determine segment numbers and order
    $line = <$fh>;
    @fields = split(/,/, $line);
    for ($i=4; $i<=$#fields; $i++) {
        if ($fields[$i] =~ /Seg_/) {
            $fields[$i] =~ s/\s*Seg_(\d+)\s*/$1/;
            push (@segs, $fields[$i]);
        }
    }
    if ($segnum ne "all") {
        if (&list_match($segnum, @segs) == -1) {
            return &pop_up_error($parent, "Invalid segment number $segnum for W2 spreadsheet file.");
        } else {
            $seg_choice = &list_match($segnum, @segs);
        }
    }

    if ($segnum eq "all") {
        for ($n=0; $n<=$#segs; $n++) {
            $i = $segs[$n];
            if (! defined($kb[$i])) {
                return &pop_up_error($parent, "Bottom-most active cell not defined for segment $i.");
            }
            if (! defined($el[$kb[$i]][$i])) {
                return &pop_up_error($parent, "Cell elevations not defined for segment $i.");
            }
        }
    } else {
        if (! defined($kb[$segnum])) {
            return &pop_up_error($parent, "Bottom-most active cell not defined for segment $segnum.");
        }
        if (! defined($el[$kb[$segnum]][$segnum])) {
            return &pop_up_error($parent, "Cell elevations not defined for segment $segnum.");
        }
    }

#   Read the file
    $n  = 0;
    $nl = 0;            # number of data lines read
    $nd = 0;            # number of dates read
    $nd_keep = 0;       # number of dates kept
    @nn = (0) x @segs;  # an array of zeroes for every segment
    $next_nl      =   250;
    $last_jd      = -9999;
    $last_jd_div  = -9999;
    $last_jd_temp = -9999;
    while (defined($line = <$fh>)) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/,+$//;
        ($pname, $jd, undef, @fields) = split(/,/, $line);
        $pname =~ s/\s+$//;
        if ($pname eq "Temperature") {
            if ($jd != $last_jd_temp) {
                $nd++;
                $nd_keep++ if (($nd-1) % ($nskip+1) == 0);
            }
            $last_jd_temp = $jd;
        }
        if ($pname eq $parm) {
            $dt = &jdate2date($jd + $begin_jd -1);
            if ($segnum eq "all") {
                @nn = (0) x @segs if ($jd != $last_jd);
                if (($nd-1) % ($nskip+1) == 0) {
                    for ($i=0; $i<=$#segs; $i++) {
                        if ($fields[2*$i+1] != -99) {
                            $elev_data{$dt}{$segs[$i]}          = $fields[2*$i] +0. if ($nn[$i] == 0);
                            $parm_data{$dt}{$segs[$i]}[$nn[$i]] = $fields[2*$i +1] +0.;
                            $nn[$i]++;
                        }
                    }
                }
            } else {
                $n = 0 if ($jd != $last_jd);
                if (($nd-1) % ($nskip+1) == 0) {
                    if ($fields[2*$seg_choice+1] != -99.) {
                        $elev_data{$dt}     = $fields[2*$seg_choice] +0. if ($n == 0);
                        $parm_data{$dt}[$n] = $fields[2*$seg_choice +1] +0.;
                        $n++;
                    }
                }
            }
            $last_jd = $jd;

        } elsif ($pname eq $parm_div) {
            $dt = &jdate2date($jd + $begin_jd -1);
            if ($segnum eq "all") {
                @nn = (0) x @segs if ($jd != $last_jd_div);
                if (($nd-1) % ($nskip+1) == 0) {
                    for ($i=0; $i<=$#segs; $i++) {
                        if ($fields[2*$i+1] != -99) {
                            $div_data{$dt}{$segs[$i]}[$nn[$i]] = $fields[2*$i +1] +0.;
                            $nn[$i]++;
                        }
                    }
                }
            } else {
                $n = 0 if ($jd != $last_jd_div);
                if (($nd-1) % ($nskip+1) == 0) {
                    if ($fields[2*$seg_choice+1] != -99.) {
                        $div_data{$dt}[$n] = $fields[2*$seg_choice +1] +0.;
                        $n++;
                    }
                }
            }
            $last_jd_div = $jd;
        }
        $nl++;
        if ($nl >= $next_nl) {
            $next_nl += 250;
            &update_progress_bar($pbar, $nl);
        }
    }

#   Close the file
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 spreadsheet file:\n$file");

#   Change the elevation data into water-surface elevations and infer the surface-layer index.
#   This may or may not work well if the branch slope is not zero, but we'll try anyway.
#   Spreadsheet elevation data are the water-surface elevation minus the mean cell depth.
    if ($segnum eq "all") {
        foreach $dt (keys %parm_data) {
            $nlayers = $#{ $parm_data{$dt}{$i} } +1;
            for ($n=0; $n<=$#segs; $n++) {
                $i = $segs[$n];
                $elev_data{$dt}{$i} = 2 *$elev_data{$dt}{$i} -$el[$kb[$i] +1 -($nlayers -1)][$i];
                $kt_data{$dt}{$i}   = $kb[$i] -($nlayers -1);
            }
        }
    } else {
        foreach $dt (keys %parm_data) {
            $nlayers = $#{ $parm_data{$dt} } +1;
            $elev_data{$dt} = 2 *$elev_data{$dt} -$el[$kb[$segnum] +1 -($nlayers -1)][$segnum];
            $kt_data{$dt}   = $kb[$segnum] -($nlayers -1);
        }
    }

#   Divide the parameter value by the value of parm_div, if requested
    if ($parm_div ne "None") {
        &reset_progress_bar($pbar, $nd_keep, "Computing parameter values... date 1");
        $nd = -1;
        if ($parm_div eq "Temperature") {
            if ($segnum eq "all") {
                foreach $dt (sort numerically keys %parm_data) {
                    for ($i=0; $i<=$#segs; $i++) {
                        for ($n=0; $n<=$#{ $parm_data{$dt}{$segs[$i]} }; $n++) {
                            if (abs($div_data{$dt}{$segs[$i]}[$n]) > 0.1) {
                                $parm_data{$dt}{$segs[$i]}[$n] /= $div_data{$dt}{$segs[$i]}[$n];
                                if ($parm_data{$dt}{$segs[$i]}[$n] < 0.0) {
                                    $parm_data{$dt}{$segs[$i]}[$n] = 0.0;
                                }
                            } else {
                                $parm_data{$dt}{$segs[$i]}[$n] = 0.0;
                            }
                        }
                    }
                    if (++$nd % 10 == 0) {
                        &update_progress_bar($pbar, $nd, $dt);
                    }
                }
            } else {
                foreach $dt (sort numerically keys %parm_data) {
                    for ($n=0; $n<=$#{ $parm_data{$dt} }; $n++) {
                        if (abs($div_data{$dt}[$n]) > 0.1) {
                            $parm_data{$dt}[$n] /= $div_data{$dt}[$n];
                            $parm_data{$dt}[$n] = 0.0 if ($parm_data{$dt}[$n] < 0.0);
                        } else {
                            $parm_data{$dt}[$n] = 0.0;
                        }
                    }
                    if (++$nd % 10 == 0) {
                        &update_progress_bar($pbar, $nd, $dt);
                    }
                }
            }
        } else {
            if ($segnum eq "all") {
                foreach $dt (sort numerically keys %parm_data) {
                    for ($i=0; $i<=$#segs; $i++) {
                        for ($n=0; $n<=$#{ $parm_data{$dt}{$segs[$i]} }; $n++) {
                            if ($div_data{$dt}{$segs[$i]}[$n] != 0.) {
                                $parm_data{$dt}{$segs[$i]}[$n] /= $div_data{$dt}{$segs[$i]}[$n];
                            }
                        }
                    }
                    if (++$nd % 10 == 0) {
                        &update_progress_bar($pbar, $nd, $dt);
                    }
                }
            } else {
                foreach $dt (sort numerically keys %parm_data) {
                    for ($n=0; $n<=$#{ $parm_data{$dt} }; $n++) {
                        if ($div_data{$dt}[$n] != 0.) {
                            $parm_data{$dt}[$n] /= $div_data{$dt}[$n];
                        }
                    }
                    if (++$nd % 10 == 0) {
                        &update_progress_bar($pbar, $nd, $dt);
                    }
                }
            }
        }
    }

    return (\%kt_data, \%elev_data, \%parm_data);
}


############################################################################
#
# Subroutine to scan a W2 Heat Fluxes format file or a daily or subdaily
# *Temp?.dat file for its segment numbers.
#
# Returns the largest segment and a list of the segments found.
#
sub scan_w2_file4segs {
    my ($parent, $file, $file_type) = @_;
    my (
        $fh, $i, $jd, $line, $seg, $segmax,
        @fields, @segs,
       );

    $segmax = 0;
    @segs   = ();

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 time-series file:\n$file");

#   Read the file and get the segment numbers
    if ($file_type eq "W2 Heat Fluxes format") {
        while (defined($line = <$fh>)) {
            next if ($line =~ /^\#/);
            next if ($line =~ /^JDAY,SEG,/);
            ($jd, $seg, @fields) = split(/,/, $line);
            $seg = &round_to_int($seg);
            if ($#segs > 0) {
                last if ($seg == $segs[0]);
            }
            push (@segs, $seg);
            $segmax = $seg if ($seg > $segmax);
        }

    } elsif ($file_type eq "W2 Daily *Temp.dat format") {
        for ($i=0; $i<4; $i++) {
            $line = <$fh>;          # skip four lines
        }
        while (defined($line = <$fh>)) {
            $seg = &round_to_int(substr($line,5,5));
            if ($#segs > 0) {
                last if ($seg == $segs[0]);
            }
            push (@segs, $seg);
            $segmax = $seg if ($seg > $segmax);
        }

    } elsif ($file_type eq "W2 Subdaily *Temp2.dat format") {
        for ($i=0; $i<4; $i++) {
            $line = <$fh>;          # skip four lines
        }
        while (defined($line = <$fh>)) {
            $seg = &round_to_int(substr($line,9,5));
            if ($#segs > 0) {
                last if ($seg == $segs[0]);
            }
            push (@segs, $seg);
            $segmax = $seg if ($seg > $segmax);
        }

    } else {
        return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
    }

#   Close the file
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 time-series file:\n$file");

    return ($segmax, @segs);
}


############################################################################
#
# Subroutine to read one of the following CE-QUAL-W2 output files:
#  SurfTemp.dat, SurfTemp2.dat, FlowTemp.dat, FlowTemp2.dat, VolTemp.dat, VolTemp2.dat
# These files are space-delimited and have four header lines.  The *Temp.dat
# files are daily means, while the *Temp2.dat files are subdaily.
# Assume that the segment number has been validated prior to this call.
#
# The first field is expected to be a W2-type JDAY, which will be converted
# into a date for W2Anim using the supplied begin year.
#
# Returns a hash where the date keys to the data, and the date is in
# YYYYMMDDHHmm format.
#
sub read_w2_flowtemp {
    my ($parent, $file, $parm, $byear, $segnum, $pbar) = @_;
    my (
        $begin_jd, $dt, $fh, $field, $file_type, $foo, $i, $jd, $line,
        $next_nl, $nl, $progress_bar, $seg,

        @parms,
        %ts_data,
       );

    $nl = 0;
    $next_nl = 250;
    $progress_bar = ($pbar ne "") ? 1 : 0;

    ($file_type, $foo, @parms) = &determine_ts_type($parent, $file);
    if ($file_type !~ /W2 .*aily .Temp2?\.dat format/) {
        return &pop_up_error($parent, "Invalid file format ($file_type)");
    }
    if (! defined($parm) || &list_match($parm, @parms) == -1) {
        return &pop_up_error($parent, "Invalid parameter for specified W2 output file");
    }
    $begin_jd = &date2jdate(sprintf("%04d%02d%02d", $byear, 1, 1));
    $field    = &list_match($parm, @parms);
    $segnum   = "all" if (! defined($segnum) || $segnum eq "");
    %ts_data  = ();

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 time-series file:\n$file");

#   Read the file
    for ($i=0; $i<4; $i++) {   # skip header lines
        $line = <$fh>;
    }
    while (defined( $line = <$fh> )) {
        chomp $line;
        $line =~ s/^\s+//;
        ($jd, $seg, @parms) = split(/\s+/, $line);
        $dt = &jdate2date($jd + $begin_jd -1);
        if ($segnum eq "all") {
            $ts_data{$dt}[$seg] = $parms[$field];
        } elsif ($seg == $segnum) {
            $ts_data{$dt} = $parms[$field];
        }

        $nl++;
        if ($progress_bar && $nl >= $next_nl) {
            $next_nl += 250;
            &update_progress_bar($pbar, $nl);
        }
    }

#   Close the file
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 time-series file:\n$file");

    return %ts_data;
}


############################################################################
#
# Subroutine to read a CE-QUAL-W2 HeatFluxes.csv output file.
# This file is comma-delimited.
# Assume that the segment number has been validated prior to this call.
#
# The first field is expected to be a W2-type JDAY, which will be converted
# into a date for W2Anim using the supplied begin year.
#
# Returns a hash where the date keys to the data, and the date is in
# YYYYMMDDHHmm format.
#
sub read_w2_heatfluxes {
    my ($parent, $file, $parm, $byear, $segnum, $pbar) = @_;
    my (
        $begin_jd, $dt, $fh, $field, $jd, $line, $next_nl, $nl,
        $progress_bar, $seg,

        @fields,
        %hf_data,
       );

    $nl = 0;
    $next_nl = 250;
    $progress_bar = ($pbar ne "") ? 1 : 0;

    $segnum = "all" if (! defined($segnum) || $segnum eq "");
    @fields = qw(HRTS ADER EEFR EEFN EFLW EFSW EFCI EFCO EFBR EFEO EFEI SHAD WTDR MWID);
    if (! defined($parm) || &list_match(uc($parm), @fields) == -1) {
        return &pop_up_error($parent, "Invalid parameter for W2 heat fluxes output file");
    }
    $begin_jd = &date2jdate(sprintf("%04d%02d%02d", $byear, 1, 1));
    $field    = &list_match(uc($parm), @fields);
    %hf_data  = ();

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 heat flux output file:\n$file");

#   Read the file
    while (defined($line = <$fh>)) {
        next if ($line =~ /^\#/);
        next if ($line =~ /^JDAY/);
        chomp $line;
        ($jd, $seg, @fields) = split(/,/, $line);
        $dt = &jdate2date($jd + $begin_jd -1);
        if ($segnum =~ /all/i) {
            $hf_data{$dt}[$seg] = $fields[$field];
        } elsif ($seg == $segnum) {
            $hf_data{$dt} = $fields[$field];
        }

        $nl++;
        if ($progress_bar && $nl >= $next_nl) {
            $next_nl += 250;
            &update_progress_bar($pbar, $nl);
        }
    }

#   Close the file
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 heat flux output file:\n$file");

    return %hf_data;
}


############################################################################
#
# Subroutine to read a CE-QUAL-W2 water level (wl.opt) output file.
# This file is comma-delimited.
# Assume that the segment number has been validated prior to this call.
#
# The first field is expected to be a W2-type JDAY, which will be converted
# into a date for W2Anim using the supplied begin year.
#
# Returns a hash where the date keys to the data, and the date is in
# YYYYMMDDHHmm format.
#
sub read_w2_wlopt {
    my ($parent, $file, $byear, $segnum, $pbar) = @_;
    my (
        $begin_jd, $dt, $fh, $i, $jd, $line, $next_nl, $nl, $progress_bar,
        $seg_field,

        @fields, @segs,
        %wl_data,
       );

    if (! defined($segnum)) {
        return &pop_up_error($parent, "Segment number not defined for W2 Water Level file");
    }
    if (! defined($byear) || $byear !~ /^\d+$/) {
        return &pop_up_error($parent, "Begin year not defined for W2 Water Level file");
    }
    $nl = 0;
    $next_nl = 250;
    $progress_bar = ($pbar ne "") ? 1 : 0;

    $begin_jd = &date2jdate(sprintf("%04d%02d%02d", $byear, 1, 1));
    %wl_data  = ();

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 water-level file:\n$file");

#   Read the first line and sort out any issues with the file format and segment numbers
    $line = <$fh>;
    if ($line !~ /^JDAY,SEG\s+?\d+,SEG\s+?\d+,SEG\s+?\d+/) {
        return &pop_up_error($parent,
                             "File not consistent with W2 Water Level (wl.opt) format:\n$file");
    }
    chomp $line;
    $line =~ s/,+$//;
    $line =~ s/,SEG$//;
    @segs = split(/,/, substr($line,5));
    for ($i=0; $i<=$#segs; $i++) {
        $segs[$i] =~ s/^SEG\s+?//;
    }
    if ($segnum !~ /all/i) {
        $seg_field = &list_match($segnum, @segs);
        if ($seg_field == -1) {
            return &pop_up_error($parent,
                                 "Supplied segment number ($segnum) not in W2 Water Level file:\n$file");
        }
    }

#   Read the data
    while (defined( $line = <$fh> )) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/,+$//;
        ($jd, @fields) = split(/,/, $line);
        $dt = &jdate2date($jd + $begin_jd -1);
        if ($segnum =~ /all/i) {
            for ($i=0; $i<=$#fields; $i++) {
                $wl_data{$dt}[$segs[$i]] = $fields[$i];
            }
        } else {
            $wl_data{$dt} = $fields[$seg_field];
        }

        $nl++;
        if ($progress_bar && $nl >= $next_nl) {
            $next_nl += 250;
            &update_progress_bar($pbar, $nl);
        }
    }

#   Close the file
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 water-level file:\n$file");

    return %wl_data;
}


############################################################################
#
# Scan a W2 contour plot output file for the available constituents.
# Return a list of the names of those available constituents.
# Skip epiphyton and macrophytes, due to multiple group issues w/o identifiers.
#
sub scan_w2_cpl_file {
    my ($parent, $file, $id, $pbar_img) = @_;
    my ($fh, $i, $iup, $jb, $jw, $line, $nbr, $next_nl, $nf, $nl, $nwb,
        $parm, $tecplot,
        @be, @bs, @cpl_names, @us,
       );

    $nl = $nf = $jw = 0;
    $next_nl   = 5000;
    $tecplot   = -1;
    @cpl_names = ();

#   Open the contour file.
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 contour file:\n$file");

#   Detect whether this is a Tecplot contour file
    $line = <$fh>;
    if ($line =~ /^ TITLE=\"CE-QUAL-W2\"/) {
        $line = <$fh>;
        if ($line =~ /^VARIABLES=\"Distance, m\",\"Elevation, m\",\"U/) {
            $tecplot = 1;
            $cpl_names[0] = "Temperature";
            if ($line !~ /,\"RHO\" $/ && $line !~ /,\"RHO\", \"HABITAT\" $/) {
                if ($line =~ /,\"RHO\", \"HABITAT\" ,/) {
                    $line =~ s/.*,\"RHO\", \"HABITAT\" ,//;
                } elsif ($line =~ /,\"RHO\" ,/) {
                    $line =~ s/.*,\"RHO\" ,//;
                }
                for ($i=0; $i<length($line); $i+=11) {
                    $parm = substr($line, $i+1, 8);
                    $parm =~ s/^\s+//;
                    $parm =~ s/\s+$//;
                    push (@cpl_names, $parm);
                }
            }
        }

#       Count the data lines in the file
        if ($tecplot) {
            while (<$fh>) {
                $nl++;
                if ($nl >= $next_nl) {
                    $next_nl += 5000;
                    $nf = &update_alt_progress_bar($pbar_img, $nl, $nf);
                }
            }
        }
    }

#   Reach here if the file is not a Tecplot contour file
    if ($tecplot != 1) {
        seek ($fh, 0, 0);   # push file position pointer back to beginning

#       Load arrays from previous read of a W2 control file
        if (! defined($grid{$id})
                || ! defined($grid{$id}{nwb}) || ! defined($grid{$id}{nbr})
                || ! defined($grid{$id}{bs})  || ! defined($grid{$id}{be})
                || ! defined($grid{$id}{us})) {
            return &pop_up_error($parent, "Cannot scan W2 contour file\nuntil W2 control file is read.");
        }
        $nwb = $grid{$id}{nwb};
        $nbr = $grid{$id}{nbr};
        @bs  = @{ $grid{$id}{bs} };
        @be  = @{ $grid{$id}{be} };
        @us  = @{ $grid{$id}{us} };

        for ($i=0; $i<10; $i++) {
            $line = <$fh>;
        }
        $line = <$fh>;        # check 11th line for telltale text
        if ($line =~ /^Model run at / || $line =~ /^Model restarted at /) {
            $tecplot = 0;
            $line = <$fh>;    # skip NBR line
            $line = <$fh>;    # skip IMX, KMX line
            $line = <$fh>;    # line containing US, DS for a branch
            $iup  = substr($line,0,8) +0;
            for ($jb=1; $jb<=$nbr; $jb++) {
                last if ($iup == $us[$jb]);
            }
            for ($jw=1; $jw<=$nwb; $jw++) {    # Determine waterbody index
                last if ($jb >= $bs[$jw] && $jb <= $be[$jw]);
            }
            while (defined($line = <$fh>)) {
                last if ($line =~ /^New date /);
            }
            $nl = 1;

#           Look for constituent names in 38-character text fields.
#           Skip "Epiphyton" and "Macrophytes" because it's a hassle to keep track
#             of multiple groups that aren't well labelled.
            while (defined($line = <$fh>)) {
                $nl++;
                last if ($line =~ /^New date /);
                chomp $line;
                next if (length($line) != 38 || $line !~ /[a-zA-Z]/);
                next if ($line =~ /          BHR$/ ||
                         $line =~ /            U$/ ||
                         $line =~ /           QC$/ ||
                         $line =~ /            Z$/ ||
                         $line =~ /          KTI$/ ||
                         $line =~ /    Epiphyton$/ ||
                         $line =~ /  Macrophytes$/);
                $parm = $line;
                $parm =~ s/^\s+//;
                $parm =~ s/\s+$//;
                if (&list_match($parm, @cpl_names) == -1) {
                    push (@cpl_names, $parm);
                }
            }
            $tecplot = -1 if ($#cpl_names < 0);

#           Count the data lines in the file
            if ($tecplot == 0) {
                while (<$fh>) {
                    $nl++;
                    if ($nl >= $next_nl) {
                        $next_nl += 5000;
                        $nf = &update_alt_progress_bar($pbar_img, $nl, $nf);
                    }
                }
            }
        }
    }

#   Close the contour file.
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 contour file:\n$file");

#   Return tecplot format status, number of lines, waterbody index (for non-Tecplot CPL file),
#   and names of constituents with data.
    return ($tecplot, $nl, $jw, @cpl_names);
}


############################################################################
#
# Read a W2 contour output file and return a date/time-indexed array of
# parameter values and other useful information.
#
# The W2 contour output file has a lot of information, but is a bit
# incomplete or ill-described unless some other information is available.
# For the original contour file format, it is sufficient to read part of the
# W2 control file and simply know the waterbody index (JW).  In contrast, when
# reading the Tecplot version of the W2 contour output file, it is also
# necessary to read the waterbody's bathymetry file so that the segment
# distances can be properly translated into segment numbers.
#
# Calling program provides the following:
#   parent   -- parent window of calling routine
#   id       -- graph object id requiring this information
#   jw       -- number of model layers
#   file     -- W2 contour output file
#   tecplot  -- flag indicating whether the file uses Tecplot format (1)
#   tseg     -- target segment number, or 0 for all available segments
#   parm     -- name of parameter of interest
#   parm_div -- parameter divisor, if necessary
#   byear    -- begin year, where JDAY = 1.0 on Jan 1 of that year
#   nskip    -- number of dates to skip (0 = none, 1 = every other, etc.)
#   pbar     -- progress bar widget handle
#
# The tecplot input is determined through a previous call to scan_w2_cpl_file().
#
sub read_w2_cpl_file {
    my ($parent, $id, $jw, $file, $tecplot, $tseg, $parm, $parm_div, $byear, $nskip, $pbar) = @_;
    my (
        $begin_jd, $dt, $dtot, $fh, $find_cus, $found_tseg, $got_parm,
        $got_pdiv, $i, $imx, $j, $jb, $jb_tmp, $jd, $k, $kbot, $kmx, $kt,
        $last_dist, $line, $line2, $line3, $mismatch, $mode, $nd, $nd_keep,
        $next_nl, $nl, $nn, $ns, $nseg, $offset, $parm_col, $pdiv_col,
        $seg, $skip_to_next_jb, $tol,

        @be, @bs, @cus, @dist, @div, @dlx, @ds, @dt_tmp, @el, @elws, @h,
        @kb, @parm_data, @pdiv_data, @slope, @tmp, @us, @vals, @wsel, @z,

        %cpl_data, %iseg, %xdist,
       );

    $nl = 0;            # number of data lines read
    $nd = 0;            # number of dates read
    $nd_keep = 0;       # number of dates kept
    $next_nl = 5000;
    $found_tseg = 0;

    $parm_div = "None" if (! defined($parm_div) || $parm_div eq "");
    $begin_jd = &date2jdate(sprintf("%04d%02d%02d", $byear, 1, 1));

#   Load arrays from previous read of a W2 control file
    if (! defined($grid{$id})
                    || ! defined($grid{$id}{kmx}) || ! defined($grid{$id}{slope})
                    || ! defined($grid{$id}{bs})  || ! defined($grid{$id}{be})
                    || ! defined($grid{$id}{us})  || ! defined($grid{$id}{ds})) {
        return &pop_up_error($parent, "Cannot read W2 contour file\nuntil W2 control file is read.");
    }
    @bs    = @{ $grid{$id}{bs}    };
    @be    = @{ $grid{$id}{be}    };
    @us    = @{ $grid{$id}{us}    };
    @ds    = @{ $grid{$id}{ds}    };
    @slope = @{ $grid{$id}{slope} };
    $kmx   = $grid{$id}{kmx};

#   Load arrays that may exist, or may partially exist for part of the grid
    @dlx = @{ $grid{$id}{dlx} } if (defined($grid{$id}{dlx}));
    @h   = @{ $grid{$id}{h}   } if (defined($grid{$id}{h}));
    @kb  = @{ $grid{$id}{kb}  } if (defined($grid{$id}{kb}));

#   Open the contour file.
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open W2 contour file:\n$file");

#   Tackle Tecplot format first
    if ($tecplot) {
        $line = <$fh>;
        if ($line !~ /^ TITLE=\"CE-QUAL-W2\"/) {
            return &pop_up_error($parent,
                                 "Inconsistent format for W2 contour file:\n$file");
        }
        $line = <$fh>;
        if ($parm ne "Temperature" && $line !~ /\Q$parm\E/) {
            return &pop_up_error($parent,
                                 "W2 contour file does not include $parm:\n$file");
        }
        if ($parm_div ne "None" && $parm_div ne "Temperature" && $line !~ /\Q$parm_div\E/) {
            return &pop_up_error($parent,
                                 "W2 contour file does not include $parm_div:\n$file");
        }

#       For the Tecplot format, it is necessary to read the bathymetry file.
#       This should have been done already, but it's good to check.
        if (! defined($grid{$id}{dlx}) || ! defined($grid{$id}{h})
                                       || ! defined($grid{$id}{kb})) {
            return &pop_up_error($parent, "Cannot read W2 Tecplot contour file\n"
                                        . "until W2 bathymetry file is read.");
        }
        if (! defined($dlx[$us[$bs[$jw]]]) || ! defined($dlx[$ds[$be[$jw]]]) ||
             ! defined($kb[$us[$bs[$jw]]]) || ! defined($kb[$ds[$be[$jw]]])  ||
                     ! defined($h[2][$jw]) || ! defined($h[$kmx][$jw])) {
            return &pop_up_error($parent, "Cannot read W2 Tecplot contour file\n"
                                        . "until W2 bathymetry file is read.");
        }

#       Compute some total distances for comparison to Tecplot distances
        $offset = -1;
        $dtot   = 0;
        %xdist  = ();
        for ($jb=$bs[$jw]; $jb<=$be[$jw]; $jb++) {
            $xdist{$us[$jb]} = $dtot +$dlx[$us[$jb]] /2.;
            for ($i=$us[$jb]+1; $i<=$ds[$jb]; $i++) {
                $dtot += ($dlx[$i] +$dlx[$i-1]) /2.;
                $xdist{$i} = $dtot;
            }
            $dtot += $dlx[$ds[$jb]];
            $xdist{$ds[$jb]+1} = $dtot;
        }

#       Find column indices for parameters of interest
        if ($parm eq "Temperature") {
            $parm_col = 4;
        } else {
            if ($line =~ /,\"RHO\", \"HABITAT\" ,/) {
                $parm_col = 7 +int((index($line, $parm) -82) /11.);
            } elsif ($line =~ /,\"RHO\" ,/) {
                $parm_col = 6 +int((index($line, $parm) -71) /11.);
            }
        }
        if ($parm_div ne "None") {
            if ($parm_div eq "Temperature") {
                $pdiv_col = 4;
            } else {
                if ($line =~ /,\"RHO\", \"HABITAT\" ,/) {
                    $pdiv_col = 7 +int((index($line, $parm_div) -82) /11.);
                } elsif ($line =~ /,\"RHO\" ,/) {
                    $pdiv_col = 6 +int((index($line, $parm_div) -71) /11.);
                }
            }
        } else {
            $pdiv_col = 0;
        }

#       Read the file.
#       Use temporary arrays to work backwards and assign proper segments and layers
        while (defined($line = <$fh>)) {
            $nl++;
            if ($nl >= $next_nl) {
                $next_nl += 5000;
                &update_progress_bar($pbar, $nl);
            }
            chomp $line;

#           End of data for a particular date
            if ($line =~ /^TEXT X=/) {
                next if ($nseg == -1);
                if ($nseg > -1 && $k > 0) {   # remove extra value for bottom layer
                    pop @{ $tmp[$nseg] };
                    pop @{ $div[$nseg] } if ($parm_div ne "None");
                }

#               Use Tecplot distance to assign segments (not trivial)
                if ($offset == -1) {
                    $tol = 2 *(10**(&floor(&log10($dist[$nseg])) -5));
                    $mismatch = 1;
                    for ($jb=$be[$jw]; $jb>=$bs[$jw]; $jb--) {
                        $skip_to_next_jb = 0;
                        if ($mismatch) {
                            %iseg     = ();
                            $mismatch = 0;
                            $ns       = $nseg;
                            $offset   = $dist[$nseg] -$xdist{$ds[$jb]};
                        }
                        for ($i=$ds[$jb]; $i>=$us[$jb]; $i--) {
                            if (abs($dist[$ns] -($xdist{$i} +$offset)) > $tol) {
                                $mismatch = 1;
                                for ($jb_tmp=$jb-1; $jb_tmp>=$bs[$jw]; $jb_tmp--) {
                                    if (abs($dist[$ns] -($xdist{$ds[$jb_tmp]} +$offset)) <= $tol) {
                                        $mismatch = 0;
                                        $skip_to_next_jb = 1;
                                        last;
                                    }
                                }
                                last if ($mismatch || $skip_to_next_jb);
                            }
                            if ($slope[$jb] == 0.0) {
                                $kbot = $#{ $tmp[$ns] } +$kt;
                                if ($kbot != $kb[$i]) {
                                    $mismatch = 1;
                                    last;
                                }
                            }
                            $iseg{sprintf("%.1f",$dist[$ns])} = $i;
                            $ns--;
                            last if ($ns < 0);
                        }
                        last if ($ns < 0);
                    }
                    if ($mismatch || $ns > 0) {
                        return &pop_up_error($parent,
                                     "Unable to match segment distances in W2 contour file\n"
                                   . "to segment distances from W2 bathymetry file.");
                    }

#                   Adjust reference distances
                    foreach $i (keys %xdist) {
                        $xdist{$i} += $offset;
                    }
                }

                @cus = @elws = @parm_data = @pdiv_data = ();

                $find_cus = 1;
                for ($ns=0; $ns<=$nseg; $ns++) {
                    if (defined($iseg{sprintf("%.1f",$dist[$ns])})) {
                        $i = $iseg{sprintf("%.1f",$dist[$ns])};
                    } else {
                        foreach $i (keys %xdist) {
                            if (abs($dist[$ns] -$xdist{$i}) <= $tol) {
                                $iseg{sprintf("%.1f",$dist[$ns])} = $i;
                                last;
                            }
                        }
                    }
                    for ($jb=$bs[$jw]; $jb<=$be[$jw]; $jb++) {
                        last if ($i >= $us[$jb] && $i <= $ds[$jb]);
                    }
                    $cus[$jb] = $i if ($find_cus);

                    if ($tseg == 0 || $tseg == $i) {
                        $elws[$i] = $wsel[$ns];
                        for ($k=0; $k<=$#{ $tmp[$ns] }; $k++) {
                            $parm_data[$k+$kt][$i] = $tmp[$ns][$k];
                            if ($parm_div ne "None") {
                                $pdiv_data[$k+$kt][$i] = $div[$ns][$k];
                            }
                        }
                        $found_tseg = 1;
                    }
                    $find_cus = ($i == $ds[$jb]) ? 1 : 0;
                }
                if ($nd % ($nskip+1) == 0) {
                    $cpl_data{$dt}{kt}        = $kt;
                    $cpl_data{$dt}{cus}       = [ @cus       ];
                    $cpl_data{$dt}{elws}      = [ @elws      ];
                    $cpl_data{$dt}{parm_data} = [ @parm_data ];
                    if ($parm_div ne "None") {
                        $cpl_data{$dt}{pdiv_data} = [ @pdiv_data ];
                    }
                    $nd_keep++;
                }
                $nd++;
                $nseg = -1;

#           New date starts
            } elsif ($line =~ /^ZONE T=/) {
                ($jd = $line) =~ s/^ZONE T=\"//;
                $jd  = substr($jd, 0, index($jd, '" ')) +0;
                $dt  = &jdate2date($jd + $begin_jd -1);
                ($kt = $line) =~ s/^.* I=//;
                $kt  = (substr($kt, 0, index($kt, ' J=')) * -1) +2 +$kmx;
                if ($kt < 2 || $kt > $kmx) {
                    return &pop_up_error($parent,
                                 "W2 contour file surface layer index $kt"
                               . "on JDAY $jd is outside of range 2 to $kmx:\n$file");
                }
                $k = 0;
                $nseg = -1;
                $last_dist = -999;
                @dist = @wsel = @tmp = @div = ();

#           Data line
            } elsif ($line !~ /-0.990000E\+02 -0.990000E\+02 -0.990000E\+02/) {
                $line =~ s/^\s+//;
                @vals = split(/\s+/, $line);
                if ($vals[0] == $last_dist) {
                    $k++;
                    $tmp[$nseg][$k] = $vals[$parm_col] +0;
                    $div[$nseg][$k] = $vals[$pdiv_col] +0 if ($parm_div ne "None");
                } else {
                    if ($nseg > -1 && $k > 0) {   # remove extra value for bottom layer
                        pop @{ $tmp[$nseg] };
                        pop @{ $div[$nseg] } if ($parm_div ne "None");
                    }
                    $nseg++;
                    $k = 0;
                    $dist[$nseg]    = $vals[0] +0;
                    $wsel[$nseg]    = $vals[1] +0;
                    $tmp[$nseg][$k] = $vals[$parm_col] +0;
                    $div[$nseg][$k] = $vals[$pdiv_col] +0 if ($parm_div ne "None");
                    $line = <$fh>;                # skip second line for surface layer
                    $nl++;
                }
                $last_dist = $vals[0];
            }
        }

#       Calculate grid elevations for every cell in this waterbody
        &get_grid_elevations($parent, $id, $jw);

#   Non-Tecplot contour file format
    } else {
        for ($i=0; $i<10; $i++) {
            $line = <$fh>;
        }
        $line = <$fh>;      # check 11th line for telltale text
        if ($line !~ /^Model run at / && $line !~ /^Model restarted at /) {
            return &pop_up_error($parent,
                                 "Inconsistent format for W2 contour file:\n$file");
        }
        $line = <$fh>;      # skip NBR line
        $line = <$fh>;
        $imx  = substr($line,0, 8) +0;
        $kmx  = substr($line,8,10) +0;
        for ($jb=$bs[$jw]; $jb<=$be[$jw]; $jb++) {
            $line = <$fh>;
            chomp $line;
            if (substr($line,0, 8) +0 != $us[$jb] ||
                substr($line,8,10) +0 != $ds[$jb]) {
                return &pop_up_error($parent,
                                 "Mismatch of upstream or downstream segments in branch.");
            }
            $i = $us[$jb];
            while (defined($line = <$fh>)) {
                chomp $line;
                $line =~ s/^\s+//;
                @vals = split(/\s+/, $line);
                for ($j=0; $j<=$#vals; $j++) {
                    $kb[$i+$j] = $vals[$j];        # read kb[]
                }
                $i += $#vals +1;
                last if ($i > $ds[$jb]);
            }
        }
        $i = 1;
        while (defined($line = <$fh>)) {
            chomp $line;
            $line =~ s/^\s+//;
            @vals = split(/\s+/, $line);
            for ($j=0; $j<=$#vals; $j++) {
                $dlx[$i+$j] = $vals[$j];           # read dlx[]
            }
            $i += $#vals +1;
            last if ($i > $imx);
        }
        $k = 1;
        while (defined($line = <$fh>)) {
            chomp $line;
            $line =~ s/^\s+//;
            @vals = split(/\s+/, $line);
            for ($j=0; $j<=$#vals; $j++) {
                $h[$k+$j][$jw] = $vals[$j];        # read h[]
            }
            $k += $#vals +1;
            last if ($k > $kmx);
        }

#       Skip forward to line with "New date" and set KT
        while (defined($line = <$fh>)) {
            if ($line =~ /^New date /) {
                chomp $line;
                ($jd  = $line) =~ s/^New date\s+([0-9\.]+)\s+.*$/$1/;
                $dt   = &jdate2date($jd + $begin_jd -1);
                $line = <$fh>;
                chomp $line;
                $kt   = $line +0;
                last;
            }
        }
        @cus = @z = @parm_data = @pdiv_data = ();

#       Look for certain parameters and read their data
        $nl   = 2;       # start data line number here
        $mode = "cus";
        while (defined($line = <$fh>)) {
            $nl++;
            if ($nl >= $next_nl) {
                $next_nl += 5000;
                &update_progress_bar($pbar, $nl);
            }
            chomp $line;
            if ($line =~ /^New date /) {
                if ($nd % ($nskip+1) == 0) {
                    $cpl_data{$dt}{kt}        = $kt;
                    $cpl_data{$dt}{cus}       = [ @cus       ];
                    $cpl_data{$dt}{z}         = [ @z         ];
                    $cpl_data{$dt}{parm_data} = [ @parm_data ];
                    if ($parm_div ne "None") {
                        $cpl_data{$dt}{pdiv_data} = [ @pdiv_data ];
                    }
                    $nd_keep++;
                }
                $nd++;
                @cus = @z = @parm_data = @pdiv_data = ();

                ($jd  = $line) =~ s/^New date\s+([0-9\.]+)\s+.*$/$1/;
                $dt   = &jdate2date($jd + $begin_jd -1);
                $line = <$fh>;
                $nl++;
                chomp $line;
                $kt   = $line +0;
                $mode = "cus";
            }
            if ($mode eq "cus") {
                if (length($line) == 38 && $line =~ /       BHR$/) {
                    $seg = $line3 +0;
                    for ($jb=$bs[$jw]; $jb<=$be[$jw]; $jb++) {
                        last if ($seg >= $us[$jb] && $seg <= $ds[$jb]);
                    }
                    $cus[$jb] = $seg;
                    $mode = "z";
                }
                $line3 = $line2;
                $line2 = $line;

            } elsif ($mode eq "z" && length($line) == 38 && $line =~ /        Z$/) {
                $i = $cus[$jb];
                while (defined($line = <$fh>)) {
                    $nl++;
                    if ($nl >= $next_nl) {
                        $next_nl += 5000;
                        &update_progress_bar($pbar, $nl);
                    }
                    chomp $line;
                    $line =~ s/^\s+//;
                    @vals = split(/\s+/, $line);
                    for ($j=0; $j<=$#vals; $j++) {
                        $z[$i+$j] = $vals[$j];
                    }
                    $i += $#vals +1;
                    last if ($i > $ds[$jb]);
                }
                $mode = "parm";
                $got_parm = $got_pdiv = 0;

            } elsif ($mode eq "parm" && length($line) == 38 && $line =~ /\Q$parm\E/) {
                $got_parm = 1;
                for ($i=$cus[$jb]; $i<=$ds[$jb]; $i++) {
                    for ($k=$kt; $k<=$kb[$i]; $k+=9) {
                        $line = <$fh>;
                        $nl++;
                        if ($nl >= $next_nl) {
                            $next_nl += 5000;
                            &update_progress_bar($pbar, $nl);
                        }
                        next if ($tseg > 0 && $tseg != $i);
                        chomp $line;
                        $line =~ s/^\s+//;
                        @vals = split(/\s+/, $line);
                        for ($j=0; $j<=$#vals; $j++) {
                            $parm_data[$k+$j][$i] = $vals[$j];
                        }
                        $found_tseg = 1;
                    }
                    if ($i < $ds[$jb]) {
                        $line = <$fh>;
                        $nl++;
                        if ($nl >= $next_nl) {
                            $next_nl += 5000;
                            &update_progress_bar($pbar, $nl);
                        }
if ($line !~ /\Q$parm\E/) {
  print "parm problem\n";
  print "nl:   $nl\n";
  print "jd:   $jd\n";
  print "dt:   $dt\n";
  print "kt:   $kt\n";
  print "kb:   $kb[$i]\n";
  print "i:    $i\n";
  print "jb:   $jb\n";
  print "cus:  $cus[$jb]\n";
  print "line: $line";
  exit;
}
                    }
                }
                $mode = "cus" if ($parm_div eq "None" || $got_pdiv);

            } elsif ($mode eq "parm" && length($line) == 38 && $line =~ /\Q$parm_div\E/) {
                $got_pdiv = 1;
                for ($i=$cus[$jb]; $i<=$ds[$jb]; $i++) {
                    for ($k=$kt; $k<=$kb[$i]; $k+=9) {
                        $line = <$fh>;
                        $nl++;
                        if ($nl >= $next_nl) {
                            $next_nl += 5000;
                            &update_progress_bar($pbar, $nl);
                        }
                        next if ($tseg > 0 && $tseg != $i);
                        chomp $line;
                        $line =~ s/^\s+//;
                        @vals = split(/\s+/, $line);
                        for ($j=0; $j<=$#vals; $j++) {
                            $pdiv_data[$k+$j][$i] = $vals[$j];
                        }
                    }
                    if ($i < $ds[$jb]) {
                        $line = <$fh>;
                        $nl++;
                        if ($nl >= $next_nl) {
                            $next_nl += 5000;
                            &update_progress_bar($pbar, $nl);
                        }
print "parm_div problem\n" if ($line !~ /\Q$parm_div\E/);
                    }
                }
                $mode = "cus" if ($got_parm);
            }
        }
        if (! defined($cpl_data{$dt}{kt})) {
            if ($nd % ($nskip+1) == 0) {
                $cpl_data{$dt}{kt}        = $kt;
                $cpl_data{$dt}{cus}       = [ @cus       ];
                $cpl_data{$dt}{z}         = [ @z         ];
                $cpl_data{$dt}{parm_data} = [ @parm_data ];
                if ($parm_div ne "None") {
                    $cpl_data{$dt}{pdiv_data} = [ @pdiv_data ];
                }
                $nd_keep++;
            }
            $nd++;
        }

#       Calculate grid elevations for every cell in this waterbody
        &get_grid_elevations($parent, $id, $jw);
        @el = @{ $grid{$id}{el} };

#       Compute water-surface elevations and grid elevations
        &reset_progress_bar($pbar, $nd_keep, "Computing water-surface elevations... date 1");
        $nn = 0;
        @dt_tmp = sort numerically keys %cpl_data;
        for ($j=0; $j<=$#dt_tmp; $j++) {
            $dt   = $dt_tmp[$j];
            @elws = ();
            $kt   = $cpl_data{$dt}{kt};
            @cus  = @{ $cpl_data{$dt}{cus} };
            @z    = @{ $cpl_data{$dt}{z}   };
            for ($jb=$bs[$jw]; $jb<=$be[$jw]; $jb++) {
                if (defined($cus[$jb])) {
                    for ($i=$cus[$jb]; $i<=$ds[$jb]; $i++) {
                        next if ($tseg > 0 && $tseg != $i);
                        $elws[$i] = $el[$kt][$i] -$z[$i];
                    }
                }
            }
            $cpl_data{$dt}{elws} = [ @elws ];
            delete $cpl_data{$dt}{z};

            if (++$nn % 10 == 0) {
                &update_progress_bar($pbar, $nn, $dt);
            }
        }

#       Store some variables if a bathymetry file has not been read
        $grid{$id}{dlx} = [ @dlx ];
        $grid{$id}{h}   = [ @h   ];
        $grid{$id}{kb}  = [ @kb  ];
    }

#   Close the contour file and return.
    close ($fh)
        or &pop_up_info($parent, "Unable to close W2 contour file:\n$file");

#   Return with an error if target segment not found.
    if ($tseg > 0 && ! $found_tseg) {
        return &pop_up_error($parent, "Target segment ($tseg) not found\nin W2 contour file:\n$file");
    }

#   Divide the parameter values by the parm_div values, if needed.
    if ($parm_div ne "None") {
        &reset_progress_bar($pbar, $nd_keep, "Calculating parameter values... date 1");
        $nn = -1;
        @dt_tmp = sort numerically keys %cpl_data;
        if ($parm_div eq "Temperature") {
            for ($j=0; $j<=$#dt_tmp; $j++) {
                $dt        = $dt_tmp[$j];
                $kt        = $cpl_data{$dt}{kt};
                @cus       = @{ $cpl_data{$dt}{cus}       };
                @parm_data = @{ $cpl_data{$dt}{parm_data} };
                @pdiv_data = @{ $cpl_data{$dt}{pdiv_data} };
                for ($jb=$bs[$jw]; $jb<=$be[$jw]; $jb++) {
                    next if (! defined($cus[$jb]));
                    for ($i=$cus[$jb]; $i<=$ds[$jb]; $i++) {
                        next if ($tseg > 0 && $tseg != $i);
                        for ($k=$kt; $k<=$kb[$i]; $k++) {
                            if (abs($pdiv_data[$k][$i]) > 0.1) {
                                $parm_data[$k][$i] /= $pdiv_data[$k][$i];
                                $parm_data[$k][$i] = 0.0 if ($parm_data[$k][$i] < 0.0);
                            } else {
                                $parm_data[$k][$i] = 0.0;
                            }
                        }
                    }
                }
                $cpl_data{$dt}{parm_data} = [ @parm_data ];
                delete $cpl_data{$dt}{pdiv_data};

                if (++$nn % 10 == 0) {
                    &update_progress_bar($pbar, $nn, $dt);
                }
            }
        } else {
            for ($j=0; $j<=$#dt_tmp; $j++) {
                $dt        = $dt_tmp[$j];
                $kt        = $cpl_data{$dt}{kt};
                @cus       = @{ $cpl_data{$dt}{cus}       };
                @parm_data = @{ $cpl_data{$dt}{parm_data} };
                @pdiv_data = @{ $cpl_data{$dt}{pdiv_data} };
                for ($jb=$bs[$jw]; $jb<=$be[$jw]; $jb++) {
                    next if (! defined($cus[$jb]));
                    for ($i=$cus[$jb]; $i<=$ds[$jb]; $i++) {
                        next if ($tseg > 0 && $tseg != $i);
                        for ($k=$kt; $k<=$kb[$i]; $k++) {
                            if ($pdiv_data[$k][$i] != 0.) {
                                $parm_data[$k][$i] /= $pdiv_data[$k][$i];
                            }
                        }
                    }
                }
                $cpl_data{$dt}{parm_data} = [ @parm_data ];
                delete $cpl_data{$dt}{pdiv_data};

                if (++$nn % 10 == 0) {
                    &update_progress_bar($pbar, $nn, $dt);
                }
            }
        }
    }

    return %cpl_data;
}


############################################################################
#
# Read a bulkhead configuration file for the Libby Dam selective withdrawal
# algorithm. Inputs include:
#
#  Number of wet wells
#  Names of the wet wells, to match with names in outlet release rate file
#  Number of bulkhead rows blocking each wet well, numbered from bottom up
#  Number of vertical slots (per wet well) that each hold a stack of bulkheads
#  Width of each identical bulkhead piece
#  Height of each bulkhead row
#  Baseline elevation (bottom of bulkhead row 1)
#  Baseline head-loss coefficient for lowest open bulkhead row
#  Incremental addition to head-loss coefficient for each row above baseline
#  Dates and number of missing bulkheads in each row for each wet well
#  
sub read_libby_config {
    my ($parent, $lbc_file) = @_;
    my (
        $base_elev, $base_elev_units, $bh_height, $bh_height_units,
        $bh_width, $bh_width_units, $d, $date_found, $date_only, $dt,
        $fh, $field, $h, $hlc_base, $hlc_inc, $i, $jd, $line, $m, $mi,
        $num_rows, $num_ww, $nw, $pos, $units, $value, $y,

        @max_slots, @num_open_bh, @num_slots, @vals, @ww_names,

        %bh_config, %bh_miss,
       );

#   Initialize variables for Libby Dam configuration
    $num_ww          =  2;
    $num_rows        = 18;
    $bh_width        = 27.0;
    $bh_width_units  = "feet";
    $bh_height       = 10.34;
    $bh_height_units = "feet";
    $base_elev       = 2222;
    $base_elev_units = "feet";
    $hlc_base        = 0.5;
    $hlc_inc         = 0.2;
    @ww_names        = ();
    @max_slots       = ();
    @num_slots       = ();
    %bh_miss         = ();

#   Open the specified bulkhead configuration file
    open ($fh, $lbc_file) or
        return &pop_up_error($parent, "Unable to open bulkhead configuration file:\n$lbc_file");

#   Read the expected metadata
    while (defined( $line = <$fh> )) {
        chomp $line;
        $line =~ s/,+$//;
        ($date_found, $date_only) = &found_date($line);

#       If not a date input, then read the metadata
        if (! $date_found) {
            $pos   = index($line, ",");
            $field = substr($line, 0, $pos);
            $value = substr($line, $pos +1);
            $value =~ s/^\s+//;

            if ($field =~ /Wet Wells/) {
                if ($value !~ /[0-9]+/) {
                    &pop_up_error($parent, "Number of wet wells must be a number:\n$lbc_file");
                    return;
                }
                $num_ww = $value;
            } elsif ($field =~ /WW Names/) {
                @ww_names = split(/,/, $value);
            } elsif ($field =~ /Bulkhead Slots/) {
                if ($value !~ /[0-9]+/) {
                    &pop_up_error($parent, "Number of bulkhead slots must be a number:\n$lbc_file");
                    return;
                }
                @num_slots = split(/,/, $value);
            } elsif ($field =~ /Bulkhead Rows/) {
                if ($value !~ /[0-9]+/) {
                    &pop_up_error($parent, "Number of bulkhead rows must be a number:\n$lbc_file");
                    return;
                }
                $num_rows = $value;
            } elsif ($field =~ /Bulkhead Width/) {
                ($value, $units) = split(/,/, $value);
                if ($value !~ /[0-9]+/) {
                    &pop_up_error($parent, "Bulkhead width must be a number:\n$lbc_file");
                    return;
                }
                if ($units !~ /^(ft|foot|feet|m|meter|meters)$/i) {
                    &pop_up_error($parent, "Bulkhead width units must be feet or meters:\n$lbc_file");
                    return;
                }
                $bh_width       = $value;
                $bh_width_units = ($units =~ /(ft|foot|feet)/i) ? "feet" : "meters";
            } elsif ($field =~ /Bulkhead Height/) {
                ($value, $units) = split(/,/, $value);
                if ($value !~ /[0-9]+/) {
                    &pop_up_error($parent, "Bulkhead height must be a number:\n$lbc_file");
                    return;
                }
                if ($units !~ /^(ft|foot|feet|m|meter|meters)$/i) {
                    &pop_up_error($parent, "Bulkhead height units must be feet or meters:\n$lbc_file");
                    return;
                }
                $bh_height       = $value;
                $bh_height_units = ($units =~ /(ft|foot|feet)/i) ? "feet" : "meters";
            } elsif ($field =~ /Baseline Elevation/) {
                ($value, $units) = split(/,/, $value);
                if ($value !~ /[0-9]+/) {
                    &pop_up_error($parent, "Baseline elevation must be a number:\n$lbc_file");
                    return;
                }
                if ($units !~ /^(ft|foot|feet|m|meter|meters)$/i) {
                    &pop_up_error($parent, "Baseline elevation units must be feet or meters:\n$lbc_file");
                    return;
                }
                $base_elev       = $value;
                $base_elev_units = ($units =~ /(ft|foot|feet)/i) ? "feet" : "meters";
            } elsif ($field =~ /Baseline Head Loss Coef/) {
                if ($value !~ /[0-9]+/) {
                    &pop_up_error($parent, "Baseline head loss coefficient must be a number:\n$lbc_file");
                    return;
                }
                $hlc_base = $value;
            } elsif ($field =~ /Head Loss Increment/) {
                if ($value !~ /[0-9]+/) {
                    &pop_up_error($parent, "Head loss coefficient increment must be a number:\n$lbc_file");
                    return;
                }
                $hlc_inc = $value;
            }

#       Otherwise, date-related data have been found.
#       Expect date, then JDAY, then the number of open bulkheads in rows 1-max of first wet well,
#        followed by the same info for other wet wells.
        } else {
            @vals = split(/,/, $line);
            $dt   = shift(@vals);
            $jd   = shift(@vals);  # won't be using this, but it's needed for W2 input
            @num_open_bh = ();
            for ($nw=0; $nw<$num_ww; $nw++) {
                $max_slots[$nw] = 0;
                for ($i=0; $i<$num_rows; $i++) {
                    $num_open_bh[$nw][$i] = $vals[($num_rows*$nw)+$i];
                    if ($num_open_bh[$nw][$i] > $max_slots[$nw]) {
                        $max_slots[$nw] = $num_open_bh[$nw][$i];
                    }
                }
            }
            if ($date_only) {
                ($m, $d, $y) = &parse_date($dt, $date_only);
                $dt = sprintf("%04d%02d%02d", $y, $m, $d);
            } else {
                ($m, $d, $y, $h, $mi) = &parse_date($dt, $date_only);
                $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
            }
            $bh_miss{$dt} = [ @num_open_bh ];
        }
    }

#   Close the bulkhead configuration file.
    close ($fh)
        or &pop_up_info($parent, "Unable to close bulkhead configuration file:\n$lbc_file");

#   Ensure that a slot number is specified for each wet well, and that the number of slots is
#   no less than the maximum specified number of open bulkhead positions for any row.
    for ($nw=0; $nw<$num_ww; $nw++) {
        if (! defined($num_slots[$nw]) || $num_slots[$nw] <= 0) {
            &pop_up_error($parent, "Check the number of bulkhead slots for wet well "
                                   . $nw+1 . ":\n$lbc_file");
            return;
        }
        if ($num_slots[$nw] < $max_slots[$nw]) {
            &pop_up_error($parent, "Number of bulkhead slots for wet well " . $nw+1
                                 . "is less than the maximum number of open slots "
                                 . "for that wet well:\n$lbc_file");
            return;
        }
    }

#   Check for wet well names
    for ($nw=0; $nw<$num_ww; $nw++) {
        if (! defined($ww_names[$nw]) || $ww_names[$nw] eq "") {
            &pop_up_error($parent, "You must specify names for the wet well outlets\n"
                                 . "in the bulkhead configuration file:\n$lbc_file");
            return;
        }
    }

#   Convert bulkhead stuff to meters
    $bh_width  /= 3.28084 if ($bh_width_units  eq "feet");
    $bh_height /= 3.28084 if ($bh_height_units eq "feet");
    $base_elev /= 3.28084 if ($base_elev_units eq "feet");

#   Populate a hash to return
    $bh_config{num_ww}    = $num_ww;
    $bh_config{ww_names}  = [ @ww_names  ];
    $bh_config{num_slots} = [ @num_slots ];
    $bh_config{num_rows}  = $num_rows;
    $bh_config{bh_width}  = $bh_width;      # meters
    $bh_config{bh_height} = $bh_height;     # meters
    $bh_config{base_elev} = $base_elev;     # meters
    $bh_config{hlc_base}  = $hlc_base;
    $bh_config{hlc_inc}   = $hlc_inc;
    $bh_config{bh_miss}   = { %bh_miss };

    return %bh_config;
}


############################################################################
#
# Downstream withdrawal subroutine translated from CE-QUAL-W2
#
sub downstream_withdrawal {
    my (%parms) = @_;
    my (
        $coef, $dlrhob, $dlrhomax, $dlrhot, $elstr, $estr, $g, $hb, $hswb,
        $hswt, $ht, $k, $kb, $kbot, $kbsw, $kmx, $kstr, $kt, $ktop, $ktsw,
        $nonzero, $point_sink, $qstr, $qsum, $ratio, $rhofb, $rhoft, $tavg,
        $vsum, $wsel, $wstr,

        @b, @el, @qout, @rho, @t, @vnorm
        );

#   Get parameters.
    $kmx  = $parms{kmx};
    $kb   = $parms{kb};
    $ktsw = $parms{ktsw};
    $kbsw = $parms{kbsw};
    $qstr = $parms{qstr};      # cms
    $estr = $parms{estr};      # meters
    $wstr = $parms{wstr};      # meters
    $wsel = $parms{wsel};      # meters
    @b    = @{ $parms{b}   };  # meters
    @el   = @{ $parms{el}  };  # meters
    @t    = @{ $parms{wt}  };  # deg C
    @rho  = @{ $parms{rho} };  # kg/cu.m.

#   If zero flow, return defaults
    if ($qstr == 0.) {
        @qout = ();
        for ($k=2; $k<=$kmx; $k++) {
            $qout[$k] = 0.0;
        }
        $tavg = -99.0;
        return ($tavg, @qout);
    }

#   Initialize some variables.  Calculations are in metric units.
    $point_sink = ($wstr > 0.0) ? 0 : 1;
    $g = 9.81;
    $nonzero = 1.0E-20;
    $hswt = $hswb = 0.;

#   Set some variables
    for ($k=2; $k<=$kb; $k++) {
        last if ($el[$k] < $wsel);
    }
    $kt = $k-1;

#   Structure layer
    for ($k=$kt; $k<=$kb; $k++) {
        last if ($el[$k] < $estr);
    }
    $kstr = &max($k-1,$kt);
    $kstr = &min($kstr,$kb);

#   Initial withdrawal limits
    $ktop = &max($ktsw,$kt);
    $ktop = $kstr if ($kstr < $ktop);
    $kbot = &min($kbsw,$kb);
    $kbot = $kt+1 if ($kbot <= $kt && $kbot != $kb);
    $kbot = $kb   if ($kbot > $kb);
    $elstr = $estr;
    if ($estr <= $el[$kb+1]) {
        $kstr  = $kb;
        $elstr = $el[$kb];
    }
    $elstr = $wsel if ($estr > $el[$kt]);
    if ($kbsw < $kstr) {
        $kstr  = $kt;
        $elstr = $wsel;
    }

#   Boundary interference
    $coef = 1.0;
    if ($wsel - $el[$kbot] != 0.0) {
        $ratio = ($elstr - $el[$kbot]) / ($wsel - $el[$kbot]);
        $coef  = 2.0 if ($ratio < 0.1 || $ratio > 0.9);
    }

#   Withdrawal zone above structure
    for ($k=$kstr-1; $k>=$ktop; $k--) {

#       Density frequency
        $ht    = $el[$k] - $elstr;
        $rhoft = &max(sqrt((abs($rho[$k]-$rho[$kstr]))/($ht*$rho[$kstr]+$nonzero)*$g), $nonzero);

#       Thickness
        if ($point_sink) {
            $hswt = ($coef*$qstr/$rhoft)**0.333333;
        } else {
            $hswt = sqrt(2.0*$coef*$qstr/($wstr*$rhoft));
        }
        if ($ht > $hswt) {
            $ktop = $k;
            last;
        }
    }

#   Reference density
    if ($elstr + $hswt < $wsel) {
        $dlrhot = abs($rho[$kstr]-$rho[$ktop]);
        for ($k=$ktop+1; $k<=$kstr-1; $k++) {
            if (abs($rho[$kstr]-$rho[$k]) > $dlrhot) {
                $dlrhot = abs($rho[$kstr]-$rho[$k]);
            }
        }
    } elsif ($wsel == $elstr) {
        $dlrhot = $nonzero;
    } else {
        $dlrhot = abs($rho[$kstr]-$rho[$kt]);
        for ($k=$kt+1; $k<=$kstr-1; $k++) {
            if (abs($rho[$kstr]-$rho[$k]) > $dlrhot) {
                $dlrhot = abs($rho[$kstr]-$rho[$k]);
            }
        }
        $dlrhot *= $hswt/($wsel-$elstr);
    }
    $dlrhot = &max($dlrhot,$nonzero);

#   Withdrawal zone below structure
    for ($k=$kstr+1; $k<=$kbot; $k++) {

#       Density frequency
        $hb    = $elstr - $el[$k];
        $rhofb = &max(sqrt((abs($rho[$k]-$rho[$kstr]))/($hb*$rho[$kstr]+$nonzero)*$g), $nonzero);

#       Thickness
        if ($point_sink) {
            $hswb = ($coef*$qstr/$rhofb)**0.333333;
        } else {
            $hswb = sqrt(2.0*$coef*$qstr/($wstr*$rhofb));
        }
        if ($hb > $hswb) {
            $kbot = $k;
            last;
        }
    }

#   Reference density
    if ($elstr - $hswb > $el[$kbot+1]) {
        $dlrhob = abs($rho[$kstr]-$rho[$kbot]);
        for ($k=$kbot-1; $k>=$kstr+1; $k--) {
            if (abs($rho[$kstr]-$rho[$k]) > $dlrhob) {
                $dlrhob = abs($rho[$kstr]-$rho[$k]);
            }
        }
    } elsif ($el[$kbot+1] == $elstr) {
        $dlrhob = $nonzero;
    } else {
        $dlrhob = abs($rho[$kstr]-$rho[$kbot]);
        for ($k=$kbot-1; $k>=$kstr+1; $k--) {
            if (abs($rho[$kstr]-$rho[$k]) > $dlrhob) {
                $dlrhob = abs($rho[$kstr]-$rho[$k]);
            }
        }
        $dlrhob *= $hswb/($elstr-$el[$kbot+1]);
    }
    $dlrhob = &max($dlrhob,$nonzero);

#   Velocity profile
    @vnorm = ();
    $vsum = 0.0;
    for ($k=$ktop; $k<=$kbot; $k++) {
        if ($k > $kstr) {
            $dlrhomax = &max($dlrhob,1.0E-10);
        } else {
            $dlrhomax = &max($dlrhot,1.0E-10);
        }
        $vnorm[$k] = 1.0 - (($rho[$k]-$rho[$kstr])/$dlrhomax)**2;
        $vnorm[$k] = 1.0 if ($vnorm[$k] > 1.0);
        $vnorm[$k] = 0.0 if ($vnorm[$k] < 0.0);
        if ($k == $kt) {
            $vnorm[$k] *= $b[$k]*($wsel-$el[$k+1]);
        } else {
            $vnorm[$k] *= $b[$k]*($el[$k]-$el[$k+1]);
        }
        $vsum += $vnorm[$k];
    }

#   Outflows
    @qout = ();
    for ($k=2; $k<=$kmx; $k++) {
        $qout[$k] = 0.0;
    }
    $qsum = 0.0;
    $tavg = 0.0;
    for ($k=$ktop; $k<=$kbot; $k++) {
        $qout[$k] = ($vnorm[$k]/$vsum)*$qstr;
        $tavg    += $qout[$k]*$t[$k];
        $qsum    += $qout[$k];
    }
    if ($qsum > 0.0) {
        $tavg /= $qsum;
    } else {
        $tavg = -99.0;
    }

#   @qout is in cms
    return ($tavg, @qout);
}


#########################################################################
#
# Apply the new Libby Dam algorithm to calculate flows over and through
# a set of bulkhead openings into a wet well, returning the vertical
# distribution of horizontal flows and the mixed release temperature.
#
# The bulkheads are arranged in a user-specified number of rows aligned
# in a user-specified number of slots.  The user specifies the number
# of open bulkhead positions in each row.  The algorithm configures a
# set of virtual outlets with line widths that correspond to the total
# width of the bulkhead openings in each row.
#
# A number of variables are configured to be common to several 
# subroutines here so that their values do not have to be passed back
# and forth.
#
{
    our ($main);
    my  (
         $nvo,
         @el, @el_vo, @hlc, @ht_vo, @kstr, @lw_vo, @rho, @rho_initial,
         %ds_parms,
        );

    sub libby_calcs {
        my (
            $base_elev, $bh_height, $bh_width, $bhd, $bhdt, $bhd_tmp, $dh,
            $dh1, $dh2, $dt, $dt_tmp, $elev, $first, $hlc_base, $hlc_inc,
            $i, $k, $kb, $kmx, $last_bhd, $nr, $nrows, $nslots, $nww,
            $qstr, $qsum, $qtsum, $surf_elev, $tavg, $tout,

            @nopen_bh, @q_vo, @qout, @qvals,

            %bh_miss,
           );

#       Get the input
        ($nww, $dt, %ds_parms) = @_;

#       Initialize arrays
        @el_vo = @lw_vo = @ht_vo = @hlc = @kstr = @rho_initial = ();

#       Bulkhead variables used to set up virtual outlets
        $nslots    = $ds_parms{nslots};
        $nrows     = $ds_parms{num_rows};
        $bh_width  = $ds_parms{bh_width};    # meters
        $bh_height = $ds_parms{bh_height};   # meters
        $base_elev = $ds_parms{base_elev};   # meters
        $hlc_base  = $ds_parms{hlc_base};
        $hlc_inc   = $ds_parms{hlc_inc};
        %bh_miss   = %{ $ds_parms{bh_miss} };

#       Other variables needed for the calculations
        $kmx       = $ds_parms{kmx};
        $kb        = $ds_parms{kb};
        $surf_elev = $ds_parms{wsel};        # meters
        $qstr      = $ds_parms{qstr};        # cms
        @rho       = @{ $ds_parms{rho} };    # kg/cu.m
        @el        = @{ $ds_parms{el}  };    # meters

#       Find the date for the bulkhead openings
        $dt_tmp = (length($dt) == 8) ? $dt . "0000" : $dt;
        $first  = 1;
        foreach $bhd (sort keys %bh_miss) {
            $bhdt    = $bhd;
            $bhd_tmp = (length($bhd) == 8) ? $bhd . "0000" : $bhd;
            if ($bhd_tmp > $dt_tmp) {
                $bhdt = ($first) ? $bhd : $last_bhd;
                last;
            }
            $last_bhd = $bhd;
            $first = 0;
        }
        @nopen_bh = @{ $bh_miss{$bhdt} };

#       Set up virtual outlets:
#       Virtual outlets are located at the vertical midpoint of each row of bulkheads
#         (if a bulkhead is open at that level) and continue up to either:
#         a) the first row at which all bulkheads are missing, or
#         b) a point half a bulkhead height above the top row of bulkheads,
#            but avoiding avoiding a 1-ft skimmer at the water surface.
        $nvo = -1;
        for ($nr=0; $nr<$nrows; $nr++) {
            $elev = $base_elev +($nr +0.5) *$bh_height;
            last if ($elev > $surf_elev -1.0);
            if ($nopen_bh[$nww][$nr] > 0) {
                $nvo++;
                $el_vo[$nvo] = $elev;
                $lw_vo[$nvo] = $nopen_bh[$nww][$nr] *$bh_width;
                $ht_vo[$nvo] = $bh_height /2.;
                $hlc[$nvo]   = $hlc_base +$nvo *$hlc_inc;
                last if ($nopen_bh[$nww][$nr] == $nslots);
            }
        }
        if (($nvo < 0 || $nopen_bh[$nww][$nrows-1] < $nslots)
              && $base_elev +($nrows +0.5) *$bh_height <= $surf_elev -1.0) {
            $nvo++;
            $el_vo[$nvo] = $base_elev +($nrows +0.5) *$bh_height;
            $lw_vo[$nvo] = $nslots *$bh_width;
            $ht_vo[$nvo] = $bh_height /2.;
            $hlc[$nvo]   = $hlc_base +$nvo *$hlc_inc;
        }
#       print "Number of virtual outlets: ", $nvo+1, "  Total flow: ", $qstr, "\n";

#       If just one virtual outlet, don't bother with Howington's algorithm.
        if ($nvo == 0) {
            $q_vo[0] = $qstr;
        } else {

#           Reverse the order so that the first outlet is at the top.
            @el_vo = reverse @el_vo;
            @lw_vo = reverse @lw_vo;
            @ht_vo = reverse @ht_vo;
            @hlc   = reverse @hlc;

#           Assign densities at elevation of each virtual outlet.
#           This is a preliminary estimate of the average density of water that will
#           be flowing into each outlet.  These densities will be refined later.
            for ($i=0; $i<=$#el_vo; $i++) {
                for ($k=1; $k<=$kmx; $k++) {
                    if ($el_vo[$i] <= $el[$k] && $el_vo[$i] > $el[$k+1]) {
                        $kstr[$i]        = $k;
                        $rho_initial[$i] = $rho[$k];
                        last;
                    }
                }
            }

#           Bracket the head drop in the wet well
#           and find the optimal head drop for the release rate of interest
            $dh1 = 0.0;
            $dh2 = $surf_elev -$base_elev;
            $dh  = &zbrent_howington($dh1, $dh2, 1E-8, $qstr);
#           print "dh: $dh\n";

#           Calculate the Howington flows using this head drop
            (undef, @q_vo) = &howington_flows($dh, $qstr);
            $qsum = 0.0;
            for ($i=0; $i<=$nvo; $i++) {
                $qsum += $q_vo[$i];
            }

#           Scale the flows to ensure that the total flow is accurate
            if (abs($qsum-$qstr) > 0.0000001) {
                for ($i=0; $i<=$nvo; $i++) {
                    $q_vo[$i] *= $qstr/$qsum;
                }
            }
        }

#       Use the final virtual-outlet flows to compute the vertical
#       distribution of flows and the final mixed temperature
        @qout = ();
        for ($k=2; $k<=$kmx; $k++) {
            $qout[$k] = 0.0;
        }
        $qsum = $qtsum = 0.0;

        for ($i=0; $i<=$nvo; $i++) {
            if ($q_vo[$i] > 0.0) {
                $ds_parms{qstr} = $q_vo[$i];
                $ds_parms{estr} = $el_vo[$i];
                $ds_parms{wstr} = $lw_vo[$i];
                ($tout, @qvals) = &downstream_withdrawal(%ds_parms);
                for ($k=2; $k<=$kb; $k++) {
                    $qout[$k] += $qvals[$k];
                }
                $qsum  += $q_vo[$i];
                $qtsum += $q_vo[$i] *$tout;
            }
        }
        if ($qsum > 0.0) {
            $tavg = $qtsum /$qsum;
        } else {
            $tavg = -99.0;
        }
        return ($tavg, @qout);   # qout is in cms
    }


#########################################################################
#
#   Flow calculations using equations from Howington (1990).
#
#    Howington, S.E., 1990, Simultaneous, multiple-level withdrawal from
#       a density stratified reservoir:  U.S. Army Corps of Engineers
#       Technical Report W-90-1, 68 p. plus appendix, available at
#       https://hdl.handle.net/11681/4366.
#
#   This function returns the difference between the computed total flow
#   and the target flow, as well as an array of the flows from individual
#   outlets.  Critical flows are tested to determine whether any of the
#   outlets are blocked by density gradients.
#
    sub howington_flows {
        my ($dh, $qtarg) = @_;
        my (
            $avg_rho, $g, $i, $ii, $j, $k, $qcalc, $qrsum, $qsum, $sum,
            $sum2, $tout,
            @bh, @bhcrit, @foo, @q, @qcrit, @rho_prime,
           );

#       Initialize variables.  Calculations are done in metric units.
        $g  = 9.81;
        $dh = 0.0 if ($dh < 0.0);

        @bh = @q = @bhcrit = @qcrit = ();
        for ($i=0; $i<=$nvo; $i++) {
            $bh[$i]     = $q[$i]     = 0.0;
            $bhcrit[$i] = $qcrit[$i] = 0.0;
        }

#       Make two passes.  First pass is with initial densities and second pass
#       is with updated outlet densities.  Just two passes are useful.  More
#       than two passes with updated densities can cause oscillations in the solution.
        for ($ii=0; $ii<=1; $ii++) {
            @rho_prime = @rho_initial if ($ii == 0);

#           First, compute critical discharges for all but the top outlet.
            $sum2 = 0.0;
            for ($i=1; $i<=$nvo; $i++) {
                $sum = 0.0;
                for ($k=$kstr[$i-1]+1; $k<$kstr[$i]; $k++) {
                    $sum += ($rho[$k]-$rho[$kstr[$i-1]]) *($el[$k]-$el[$k+1]);
                }
                $sum += ($rho[$kstr[$i]]-$rho[$kstr[$i-1]]) *($el[$kstr[$i]]-$el_vo[$i]);

                $bhcrit[$i] = $sum2 + $sum/$rho_prime[$i];
                if ($bhcrit[$i] > 0.0) {
                    $qcrit[$i] = sqrt((2.0 *$g *(($lw_vo[$i]*$ht_vo[$i])**2) /$hlc[$i]) *$bhcrit[$i]);
                } else {
                    $qcrit[$i]  = 0.0;
                    $bhcrit[$i] = 0.0;
                }
                $sum2 += $sum/$rho[$kstr[$i]];
            }
            if ($qtarg <= $qcrit[$nvo]) {
                $q[$nvo] = $qtarg;
                return (0.0, @q);
            }

#           Compute flows for each outlet without consideration of the critical discharges.
            for ($i=0; $i<=$nvo; $i++) {
                if ($i == 0) {
                    $bh[$i] = 0.0;
                    $q[$i]  = sqrt((2.0 *$g *(($lw_vo[$i]*$ht_vo[$i])**2) /$hlc[$i]) *$dh);
                    $qcalc  = $q[$i];
                    next;
                }
                $qsum = $qrsum = 0;
                for ($j=0; $j<$i; $j++) {
                    $qrsum += $q[$j] *$rho_prime[$j];
                    $qsum  += $q[$j];
                }
                if ($qsum == 0.0) {
                    $avg_rho = $rho[$kstr[$i-1]];  # treat same as for critical discharge
                } else {
                    $avg_rho = $qrsum/$qsum;       # average density coming down wet well
                }
                $sum = ($rho[$kstr[$i-1]]-$avg_rho) *($el_vo[$i-1]-$el[$kstr[$i-1]+1]);
                for ($k=$kstr[$i-1]+1; $k<$kstr[$i]; $k++) {
                    $sum += ($rho[$k]-$avg_rho) *($el[$k]-$el[$k+1]);
                }
                $sum   += ($rho[$kstr[$i]]-$avg_rho) *($el[$kstr[$i]]-$el_vo[$i]);
                $bh[$i] = $bh[$i-1] +$sum/$rho_prime[$i];
                if ($bh[$i]+$dh > 0.0) {
                    $q[$i]  = sqrt((2.0 *$g *(($lw_vo[$i]*$ht_vo[$i])**2) /$hlc[$i]) *($bh[$i]+$dh));
                } else {
                    $q[$i]  = 0.0;
                    $bh[$i] = -1.0 *$dh;
                }

#               Check computed flows against critical flows.  Adjust flows if necessary.
                if ($q[$i]+0.00001 < $qcrit[$i]) {
#                   print "DH= $dh, Outlet $i flow $q[$i] less than Qcrit $qcrit[$i]. Adjusting...\n";
                    $qcalc  = 0.0;
                    $bh[$i] = $bhcrit[$i];
                    $q[$i]  = sqrt((2.0 *$g *(($lw_vo[$i]*$ht_vo[$i])**2) /$hlc[$i]) *($bh[$i]+$dh));
                    for ($j=0; $j<$i; $j++) {
                        $q[$j]  = 0.0;
                        $bh[$j] = $bhcrit[$j];
                    }
                }
                $qcalc += $q[$i];
            }

#           Scale the flows if the sum of computed flows is greater than the specified
#           total flow and the head-drop DH is zero.  Scaling the outflows is essentially
#           equivalent to scaling the height or head-loss factors equally across all outlets.
#           Not sure whether scaling is the best approach, but it is helpful.
            if ($dh == 0.0 && $qcalc > $qtarg + 0.00001) {
#               print "Total flow scaled: factor= ", $qtarg/$qcalc, "\n";
                for ($i=0; $i<=$nvo; $i++) {
                    $q[$i] *= $qtarg/$qcalc;
                }
                $qcalc = $qtarg;
            }

#           Update outlet release densities after first pass.
            if ($ii == 0) {
                for ($i=0; $i<=$nvo; $i++) {
                    if ($q[$i] > 0.0) {
                        $ds_parms{qstr} = $q[$i];
                        $ds_parms{estr} = $el_vo[$i];
                        $ds_parms{wstr} = $lw_vo[$i];
                        ($tout, @foo)   = &downstream_withdrawal(%ds_parms);
                        $rho_prime[$i]  = ((((6.536332E-9*$tout-1.120083E-6)*$tout+1.001685E-4)*$tout
                                             -9.09529E-3)*$tout+6.793952E-2)*$tout+999.842594;
                    }
                }
            }
        }
#       print "DH= $dh, Qcalc= $qcalc\n";
        return ($qcalc-$qtarg, @q);
    }


############################################################################
#
#   Apply Brent's method to find the root of the function howington_flows
#   when a root is known to lie between A and B with an accuracy of TOL.
#   The flow target is provided as the last argument.
#
    sub zbrent_howington {
        my ($a, $b, $tol, $qtarg) = @_;
        my ($c, $d, $e, $eps, $fa, $fb, $fc, $i, $itmax, $p, $q, $r, $s,
            $tol1, $xm,
            @foo,
           );

        $itmax      = 100;
        $eps        = 3.0E-10;
        ($fa, @foo) = &howington_flows($a, $qtarg);
        ($fb, @foo) = &howington_flows($b, $qtarg);
        if ($fb*$fa > 0.0) {
            return &pop_up_error($main, "Howington flows root not bracketed.\n"
                                      . "A= $a, B= $b, fA= $fa, fB= $fb");
        }
        $fc = $fb;
        for ($i=1; $i<=$itmax; $i++) {
            if ($fb*$fc > 0.0) {
                $c  = $a;    # Rename A,B,C and adjust bounding interval D.
                $fc = $fa;
                $d  = $b-$a;
                $e  = $d;
            }
            if (abs($fc) < abs($fb)) {
                $a  = $b;
                $b  = $c;
                $c  = $a;
                $fa = $fb;
                $fb = $fc;
                $fc = $fa;
            }
            $tol1 = 2.0*$eps*abs($b)+0.5*$tol;  # Convergence check.
            $xm   = 0.5*($c-$b);
            if (abs($xm) <= $tol1 || $fb == 0.0) {
#               print "Convergence at iteration $i\n";
                return $b;
            }
            if (abs($e) >= $tol1 && abs($fa) > abs($fb)) {
                $s = $fb/$fa;                   # Attempt inverse quadratic interpolation.
                if ($a == $c) {
                    $p = 2.0*$xm*$s;
                    $q = 1.0-$s;
                } else {
                    $q = $fa/$fc;
                    $r = $fb/$fc;
                    $p = $s*(2.0*$xm*$q*($q-$r)-($b-$a)*($r-1.0));
                    $q = ($q-1.0)*($r-1.0)*($s-1.0);
                }
                $q *= -1.0 if ($p > 0.0);       # Check whether in bounds.
                $p = abs($p);
                if (2.0*$p < &min(3.0*$xm*$q-abs($tol1*$q), abs($e*$q))) {
                    $e = $d;                    # Accept interpolation.
                    $d = $p/$q;
                } else {
                    $d = $xm;                   # Interpolation failed.  Use bisection.
                    $e = $d;
                }
            } else {                            # Bounds decreasing too slowly.  Use bisection.
                $d = $xm;
                $e = $d;
            }
            $a  = $b;                           # Move last best guess to A.
            $fa = $fb;
            if (abs($d) > $tol1) {              # Evaluate new trial root.
                $b += $d;
            } else {
                $b += &sign($tol1, $xm);
            }
            ($fb, @foo) = &howington_flows($b, $qtarg);
        }
        &pop_up_info($main, "ZBRENT exceeding maximum iterations.");
        return $b;
    }
}

1;
