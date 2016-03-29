use Test::More tests => 108;

chdir 'eg' or die "Can't chdir eg: $!";

unlink 'mylog.output';  # clean up from prior test

local $/ = "% ";   # Yeah, I know...

foreach my $sample (<sample*.pl>)
{
    (my $output = $sample) =~ s/pl$/output/;

    local @ARGV = $output;

    while (my $case = <>)
    {
        chomp $case;
        next if $case eq '';

        $case =~ s/^(.*)$//m;
        my $command = $1;

        $case =~ s/^\s*//;
        $case =~ s/\n\n$/\n/;

        my $output = `$command 2>&1`;   # just bundle stdout,stderr

        is($?, 0, $command);

        # Special case dates since they change

        s,\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2},_A_DATE_,g for ($output, $case);

        is($output, $case, "output $command");
    }
}
