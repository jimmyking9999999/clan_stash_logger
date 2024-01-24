

// Takes: 01/07/24, 02:49PM
// Returns: pretty much the same thing, but allows finding repeat occurances in the file.
int sale_to_timestamp(string timestamp) {
	string formatted = format_date_time("MM/dd/yy, hh:mm", timestamp, "yyyyMMddHHmm");


	if(formatted == "Bad parameter(s) passed to format_date_time"){
		print("ERROR. Bad format: " + timestamp, "red");
		return 10000000000;
	}

	return formatted.to_int();
}



string parse_indiv_line(string line){

	if(line.contains_text(" contributed ")){
		matcher item_matcher = create_matcher("<a class=nounder href='showplayer\\.php\\?who=(\\d+)'>([^<]+).*\\<\\/a\\> contributed (\\b\\d[\\d,.]*\\b)", line);

		if (item_matcher.find()) {
			/* Example: 01/07/24, 02:49PM: <a class=nounder href='showplayer.php?who=95170'>Wends (#95170)</a> contributed 69 Meat. */
			/* Returns: Wends (#95170) contributed 69 Meat   */
			return `{item_matcher.group(2)} contributed {item_matcher.group(3)} Meat`;
		} 

	}
	
	matcher item_matcher = create_matcher("<a class=nounder href='showplayer\\.php\\?who=(\\d+)'>([^<]+).*\\<\\/a\\> (took|added) (\\d+) (.*)", line);

	if (item_matcher.find()) {
		/* Example: 01/07/24, 02:49PM: <a class=nounder href='showplayer.php?who=95170'>Wends (#95170)</a> took 1 haiku katana. */
		/* Returns: Wends (#95170) took 1 haiku katana.   */
		return `{item_matcher.group(2)} {item_matcher.group(3)} {item_matcher.group(4)} {item_matcher.group(5)}`;
	} 

	return ``;

}



string[int] parse_clan_logs(){
	string [int] sales;
	int sale_number = 0;

	string low_char_log = visit_url("clan_log.php").split_string("<b>Stash Activity:</b></center><table><tr><td><font size=2>")[1];
	string[int] stash_indiv_line = low_char_log.split_string("<br>");

	int amnt = stash_indiv_line.count();
	//print(amnt, "teal");

	/* stash_indiv_line example
		01/07/24, 02:49PM: <a class=nounder href='showplayer.php?who=95170'>Wends (#95170)</a> took 1 haiku katana.
		01/07/24, 02:49PM: <a class=nounder href='showplayer.php?who=95170'>Wends (#95170)</a> took 1 Operation Patriot Shield.
		01/07/24, 02:49PM: <a class=nounder href='showplayer.php?who=95170'>Wends (#95170)</a> took 1 repaid diaper.
		01/07/24, 01:42PM: <a class=nounder href='showplayer.php?who=2437075'>Moon Moon (#2437075)</a> added 1 Pantsgiving.
		01/07/24, 01:42PM: <a class=nounder href='showplayer.php?who=2437075'>Moon Moon (#2437075)</a> added 1 Snow Suit.
		01/07/24, 01:42PM: <a class=nounder href='showplayer.php?who=2437075'>Moon Moon (#2437075)</a> added 1 Mayflower

	*/

	foreach num, it in stash_indiv_line {
		if(it.substring(0, 17) == "</font></td></tr>"){ // Weird thing to cut off the end lol
			break;
		}

		sales[num] = `{sale_to_timestamp(it.substring(0, 15))}   ---   {parse_indiv_line(it)}`;
		
	} 


	


	return sales;

}


void clan_log_data() {

	string filename = `Clan Stash Logs ({get_clan_name()}).txt`;
	


	string [int] stored_sales;
	file_to_map(filename, stored_sales);


	int latest_stored = 0; 	int new_sales_to_include = -1;



	if (stored_sales.count() > 0){
		latest_stored =  stored_sales[0].substring(0, 15).to_int();
	}




	string [int] sales = parse_clan_logs();


	foreach i, content in sales {
		int timestamp = (content.substring(0, 15)).to_int();

		string sale = content.substring(0, 15) + content.substring(sales[i].index_of("---") - 2);
		sales[i] = sale;

		if (timestamp > latest_stored) {
			new_sales_to_include = i;
		} else {
			break;
		}
	}

	string [int] new_stored_sales;

	for (int i = 0; i <= (count(stored_sales) + new_sales_to_include); i++) {
		if (i <= new_sales_to_include) {
			new_stored_sales[i] = sales[i];
		} else {
			new_stored_sales[i] = stored_sales[i - new_sales_to_include - 1];
		}
	}
	map_to_file(new_stored_sales, filename);


	print("Ignore the error message(s), it's faster to keep them in then to run a conditional on everything, haha", "orange");

	print((new_sales_to_include + 1) + " new lines of stash activity saved");
}

void main() {
	// wow this was a lot more painful then I thought 
	clan_log_data();
}

