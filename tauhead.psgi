use strict;
use warnings;

use TauHead;

my $app = TauHead->apply_default_middlewares(TauHead->psgi_app);
$app;

