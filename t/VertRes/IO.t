#!/usr/bin/perl -w
use strict;
use warnings;

BEGIN {
    use Test::Most tests => 36;
    
    use_ok('VertRes::IO');
}

my $io = VertRes::IO->new();
isa_ok $io, 'VertRes::Base';
isa_ok $io, 'VertRes::IO';

ok -d $io->catfile('t', 'data'), 'catfile on two dirs works';

# open and read from a normal file
my $file = $io->catfile('t', 'data', 'io_test.txt');
ok -f $io->file($file), 'file returns a functioning path to the file';
ok my $fh = $io->fh(), 'fh returned something';
is ref($fh), 'GLOB', 'fh returned a glob';
my @expected_lines = qw(foo bar);
while (<$fh>) {
    chomp;
    next unless $_;
    my $exp = shift @expected_lines;
    is $_, $exp, 'filehandle must have been ok';
}
$io->close();

# and from a compressed file
$file = $io->catfile('t', 'data', 'io_test.txt.gz');
ok -f $io->file($file), 'file returns a functioning path to the file';
ok $fh = $io->fh(), 'fh returned something for a .gz';
is ref($fh), 'GLOB', 'fh returned a glob';
@expected_lines = qw(foo bar);
while (<$fh>) {
    chomp;
    next unless $_;
    my $exp = shift @expected_lines;
    is $_, $exp, 'filehandle must have been ok for a .gz';
}
$io->close();

# get a temp file
($fh, $file) = $io->tempfile;
close($fh);
# write to it
is $io->file(">$file"), $file, 'filename not broken when opening for write';
$fh = $io->fh();
ok print($fh "foo bar\nbar foo\nboo far"), 'could print to an output file';
$io->close();
$io->file($file);
$fh = $io->fh();
is <$fh>, "foo bar\n", 'could read back what we wrote';
is $io->num_lines, 3, 'number of lines correct, even after manually using the filehandle';
is <$fh>, "bar foo\n", 'could read the next line even after getting the number of all lines';
$io->close();
ok -e $file, 'file exists while $io alive';
undef $io;
ok ! -e $file, 'file deleted automatically when $io destroyed';

# get a temp dir, test rmtree and get_filepaths as well
$io = VertRes::IO->new();
my $tmp_dir = $io->tempdir;
ok -d $tmp_dir, 'tmpdir created ok';
my $test_dir = $io->catfile($tmp_dir, 'test_dir');
mkdir($test_dir);
ok -d $test_dir, 'subdir created in tempdir';
my $foo_file = $io->catfile($test_dir, 'foo.txt');
system("touch $foo_file");
ok -e $foo_file, 'file created in subdir of tempdir';
my $bar_file = $io->catfile($test_dir, 'bar.gif');
system("touch $bar_file");
my $gz_file = $io->catfile($test_dir, 'llama.ps.gz');
system("touch $gz_file");
my $dot_file = $io->catfile($test_dir, '.dot');
system("touch $dot_file");
is_deeply [$io->get_filepaths($tmp_dir)], [$foo_file, $bar_file, $gz_file, $dot_file], 'get_filepaths no extra args test';
is_deeply [$io->get_filepaths($tmp_dir, suffix => 'gif')], [$bar_file], 'get_filepaths suffix test';
is_deeply [$io->get_filepaths($tmp_dir, suffix => 'ps.gz')], [$gz_file], 'get_filepaths suffix with .gz test';
is_deeply [$io->get_filepaths($tmp_dir, prefix => 'foo')], [$foo_file], 'get_filepaths prefix test';
is_deeply [$io->get_filepaths($tmp_dir, filename => 'f.+xt')], [$foo_file], 'get_filepaths filename test';
is_deeply [$io->get_filepaths($tmp_dir, subdir => 'test')], [$foo_file, $bar_file, $gz_file, $dot_file], 'get_filepaths subdir test';
is_deeply [$io->get_filepaths($tmp_dir, dir => 'test_dir')], [$test_dir], 'get_filepaths dir test';
is_deeply [$io->get_filepaths($tmp_dir, subdir => 'test', dir => 'test_dir')], [$test_dir], 'get_filepaths dir + subdir test';
is_deeply [$io->get_filepaths($tmp_dir, subdir => 'moo', dir => 'test_dir')], [], 'get_filepaths dir + bad subdir test';
is_deeply [$io->get_filepaths($tmp_dir, dir => 'moo')], [], 'get_filepaths bad dir';
$io->rmtree($test_dir);
ok ! -d $test_dir, 'rmtree removed a directory that contained a file';
undef $io;
ok ! -d $tmp_dir, 'tmpdir destroyed ok';

exit;
