use Net::Twitter;
use Graph::Easy;
my $graph     = Graph::Easy->new();
my $new_graph = $graph->copy();


my $user = "jmunson";  #TODO: commandline parsing
my $pass = "";

my $nt = Net::Twitter->new(
    traits   => [qw/API::REST/],
    username => $user,
    password => $pass'
);

my $MAX_DEPTH = 1;
mapFriends( $user, 0 );
my $root = $graph->add_node($user);    #TODO: add root attr

foreach my $node ( $graph->nodes ) {

    if ( my $edge = $graph->edge( $node, $root ) ) {    #delete any edges to me
        $graph->del_edge($edge);
    }
    else {
        $node->set_attribute( 'color', 'red' );

    }

}
foreach my $node ( $graph->nodes ) {                    #need to loop twice for the first edge deletion to take place.

    if ( $node->connections < 2 ) {                     #delete any nodes that dont have at least 3 followers
               #$graph->del_node($node)
    }

}

$graph->del_node($root);

open $DOT, '|dot -Tpng -o test.png' or die("Cannot open pipe to dot: $!");
print $DOT $graphviz;
close $DOT;

open( $out, " > /var/stuff/temp/test.svg" ); #TODO: remove hardcoded paths
print $out $graph->as_svg_file;
close($out);

open( $out, " > /var/stuff/temp/test.html" );
print $out $graph->as_html_file;
close($out);
my $depth = 0;

sub mapFriends($$) {    #target, depth.  probably not the best way to do recursion limitting, but quick and dirty
    my ( $target, $depth ) = @_;
    $depth++;
    eval {
        my $friends = $nt->following( { screen_name => $target } );
        my $i;
        for my $friend (@$friends) {

            #next if $i++ >= 10;    #debug limit

            printf STDERR ( "%s %s -> %s\n", ( "." x $depth ), $target, $friend->{screen_name} );
            next if $friend->{followers_count} > 200;    #celeb/whore filter
            $graph->add_edge_once( $target, $friend->{screen_name} );

            mapFriends( $friend->{screen_name}, $depth ) if $depth <= $MAX_DEPTH;
        }
    };

    if ( my $err = $@ ) {
        die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

        warn "HTTP Response Code: ", $err->code, "\n", "HTTP Message......: ", $err->message, "\n", "Twitter error.....: ", $err->error,
            "\n";
    }

}

