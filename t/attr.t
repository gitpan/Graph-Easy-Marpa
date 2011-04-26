use Test::More;

# ------------------------------------------------

BEGIN{ use_ok('Graph::Easy::Marpa::Parser'); }

my($parser) = Graph::Easy::Marpa::Parser -> new;

my(@attr, %attr);
my(@name);
my(@token);

$attr{background} = 'green';

push @attr, {%attr};

$attr{border} = 'bold';

push @attr, {%attr};

$attr{class} = 'fancy';

push @attr, {%attr};

$attr{fill} = 'red';

push @attr, {%attr};

$attr{label} = 'edge.label';

push @attr, {%attr};

$attr{shape} = 'circle';

push @attr, {%attr};

$attr{style} = 'broad';

push @attr, {%attr};

$attr{'text-wrap'} = 10;

push @attr, {%attr};

my($count) = 0;

for my $attr (@attr)
{
	$count++;

	@name  = ();
	@token =
	(	
	 ['left_bracket',  '['],
	 ['node_name_id',  "N.$count"],
	 ['right_bracket', ']'],
	 ['left_brace',    '{'],
	  );

	for my $key (sort keys %$attr)
	{
		push @name, "$key:$$attr{$key};";

		push @token,
		 ['attr_name_id',  $key],
	 	 ['colon',         ':'],
	 	 ['attr_value_id', $$attr{$key}],
		 ['semi_colon',    ';'];
	 }

	 push @token,
	 ['right_brace',   '}'],
	 ['edge_id',       '-'];

	ok($parser -> run(\@token) eq 'OK', "[N.$count]{" . join('', @name) . '}');
}

done_testing;
