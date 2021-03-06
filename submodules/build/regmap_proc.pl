$pre="lb_";
$clk="clk";
$defaults=0;
if ($ARGV[0] eq "-defaults") {
	shift(@ARGV);
	$defaults=1;
}
$comment_delim = $defaults ? "#" : "//";
print "$comment_delim Machine-generated by regmap_proc.pl\n";
print "$comment_delim Edit at your own risk.\n";

while (<>) {
	next if (/^#/ || !/./);
	if (/override *([-0-9]*) *(\w+)/) {
		$override{$2}=$1;  # a default value override must happen _before_ that register is defined
	} elsif (/^(\d+) *([aesu]) *\[(\d+):(\d+)\] *([-0-9]*) *(\w+)/) {
		$addr=$1;
		$typ=$2;
		$msb=$3;
		$lsb=$4;
		$def=$5;
		$name=$6;
		if (${name_ . $name}) {
			print STDERR "duplicate $name\n";
			$errors++;
		}
		${name_ . $name}=1;
		if ($lsb > $msb) {
			print STDERR "badly ordered bits in $name\n";
			$errors++;
			next;
		}
		for ($u=$lsb; $u<=$msb; $u++) {
			$bl=bit_ . $addr . "_" .$u;
			if (${$bl}) {
				print STDERR "overlapping bit in $name (previous ${$bl})\n";
				$errors++;
			}
			${$bl}=$name;
		}
		$nsb=$msb-$lsb;
		if ($typ eq "a") {
			print "`define STB_$name wire $name=((${pre}addr==$addr)&${pre}write);\n" if (!$defaults);
		} elsif ($typ eq "e") {
			if ($msb!=$lsb) {
				print STDERR "multi-bit event $name\n";
				$errors++;
			}
			print "`define EVT_$name reg $name=0; always @(posedge $clk) $name<=((${pre}addr==$addr)&${pre}write&${pre}data[$msb]);\n" if (!$defaults);
		} else {
			$signed=($typ eq "s")?"signed ":"";
			$def = $override{$name} if exists $override{$name};
			if ($def ne "-") {
				$range = 1<<($nsb+1);
				if ($def >= $range || $def < -$range) {
					print STDERR "default value $def out of range for $name\n";
					$errors++;
					# and don't try to set the bits to the flawed value
				} else {
					$def += $range if ($def < 0);  # guaranteed positive
					$default_val{$addr} = $default_val{$addr} + $def*(1<<$lsb);
				}
			}
			else {
				$def =0;
			}
			print "`define REG_$name reg ${signed}[$nsb:0] $name=$def; always @(posedge $clk) if ((${pre}addr==$addr)&${pre}write) $name<=${pre}data[$msb:$lsb];\n" if (!$defaults);
		}
	} else {
		print STDERR "unparsable $_";
		$errors++;
	}
}
if ($defaults) {
	for $f (sort {$a <=> $b} keys(%default_val)) {
		print "$f $default_val{$f}\n";
	}
}
exit ($errors!=0);
