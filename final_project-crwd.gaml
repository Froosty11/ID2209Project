/**
* Name: finalproject
* Based on the internal empty template. 
* Author: andreaslevander & edvin frosterud
* Tags: 
* 
* TODO: 
* - Add charisma system
* - Add more locations
* - Add more species
* - Add ability for Guests(everyone) to buy themselves a drink.
* - Flesh out introvert, perhaps by calculating locations where theres less people. 
* - Let people define their own targets, kinda done but could use some overviews. 
* -*/


model finalproject

/* Insert your model definition here */


global {
	float size <- 20.0;
	float guest_shoulder_length <- 1.0;
	bool avoid_others <- true;
	init {
		create Bar;
		create FoodCourt;
		create Dancer number: 4;
		create Introvert number: 12;
		create Extrovert number: 12;
	}
}

species FoodCourt {
	float money <- 0.0;
	
	aspect base {
		draw square(3) color: rgb("green");
	}
}

species Bar {
	float money <- 0.0;
	
	aspect base {
		draw square(3) color: rgb("black");
	}
}


species Guest skills: [moving, fipa, pedestrian]{
	float generosity;
	float startMoney <- 100.0;
	float money;
	float loudness;
	float happiness <- 10.0;
	bool busy <- false;
	rgb color;
	rgb baseColor;
	agent target;
	float interaction_chance <- 1.0;
	float try_to_interact <- 1.0;
	float hunger <- rnd(100.0);
	string currentLocation;
	
	float danceChance <- rnd(1.0);
	float danceTimer <- -1.0;
	float talkTime <- -1.0;
	int nearby_people_limit <- 10000;
	
    
    action initialize_pedestrian_parameters {
    	 pedestrian_model <- "simple"; // Can also be "advanced", but then you need to set corresponding parameters
        if (pedestrian_model = "simple") {
            A_pedestrians_SFM <- 2.0;
            B_pedestrians_SFM <- 0.08;
            obstacle_consideration_distance <- 3.0;
            pedestrian_consideration_distance <- 3.0;
            shoulder_length <- 1.0;
            avoid_other <- true;
            proba_detour <- 0.5;
        } else {
            // Set parameters for advanced pedestrian model... Let's not lol. 
        }
    }
    
    init {
    	money <- startMoney;
        do initialize_pedestrian_parameters;
    }
	reflex move when: target != nil {
		if location distance_to(target) < 1 {
			
			// if we arrive at the foodcourt set location to foodcourt
			if target = FoodCourt[0] {
				write name + " arrived at foodcourt";
				currentLocation <- "FoodCourt";
				target <- nil;
				busy <- false;
			}
			// if we arrive at the bar set location to the bar
			else if target = Bar[0] {
				write name + " arrived at bar";
				currentLocation <- "Bar";
				target <- nil;
				busy <- false;
			}
		}
		
		else {
			do walky_thingy t: target.location;
		}
	}
	
	action walky_thingy (point t) {
	    // Create a circle shape around the target point with a radius of 10
	    geometry area_of_interest <- circle(7, t);
	
	    // find all Guest agents within this circle
	    list<Guest> agents_nearby <- list((agents of_generic_species Guest) inside area_of_interest);
	
	    int number_of_agents_nearby <- length(agents_nearby);
	
	    write("Number of agents nearby: " + number_of_agents_nearby);
	
	    // If below the nearby_people_limit, execute the walk_to action
	    if (nearby_people_limit > number_of_agents_nearby) {
	        do walk_to target: t;
	    }
	    else{
	    	//otherwise random walk til u find a place
	    	point newTarget <- {location.x + rnd(-size, size), location.y + rnd(-size, size)} as point;
		    do walky_thingy t: newTarget;
	    }
}
	
	reflex wander when: (target = nil) {
	    point newTarget <- {location.x + rnd(-size, size), location.y + rnd(-size, size)} as point;
	    do walky_thingy t: newTarget;
    }
	
	reflex hunger {
		if hunger < 0.0 {
			hunger <- 0.0;
		}
		
		// if we are hungry go to foodcourt
		if hunger > 100.0 and !busy and currentLocation != "FoodCourt"{
			write name + " is hungry going to food court";
			busy <- true;
			target <- FoodCourt[0];
		}
		
		// if we are not hungry go party
		else if (time = 0.0 or hunger = 0.0) and !busy {
			write name + " is fed and going to the bar";
			busy <- true;
			target <- Bar[0];
		}
		
		// lower hunger if we are eating else increase hunger
		if currentLocation = "FoodCourt" {
			hunger <- hunger - rnd(1.0);
		} else {
			hunger <- hunger + rnd(1.0);
		}
		
		
	}
	
	reflex respond_to_proposal when: !empty(proposes){
		loop proposaltest over: proposes{
			string s <- proposaltest.contents[0] as string;
			Guest sender <- proposaltest.sender as Guest;
			
			
			
			switch(s){
				match "Do you want a drink?"{
					//Switch case 1: Being asked out for a drink?
					//Respond to sender
					write name + " receives question if you want a drink from " + sender;
					Bar targetBar <- proposaltest.contents[1] as Bar;
					if(flip(generosity) and !busy){ 
						do inform message: proposaltest contents: ["Yes please, I want a drink.", targetBar];
						target <- sender;
						busy <- true;
					}
					else{
						do inform message: proposaltest contents: ["No, thank you, I don't want a drink.", targetBar];
					}
				}
				match "Do you want to dance?"{
					if(flip(danceChance) and !busy){
						write(name + "joins in dancing with " + sender.name);
						danceTimer <- time + 20.0;
						busy <- true;
					}
				}
				match "Do you want to talk?"{
					if(!busy and flip(interaction_chance)){
						write(name + "starts talking with " + sender.name);
						busy <- true;
						target <- sender;
						talkTime <- time + 10.0;
						do inform message: proposaltest contents: ["Yes let's talk"];
					}
					else {
						do inform message: proposaltest contents: ["No, thank you, I am busy"];
					}
				}
			}
			
		}
		
		}
	reflex interact{
		list<agent> nearby <- (agents of_generic_species Guest) at_distance(5);
		
		// if the agent doesnt have a target and there is a
		if !busy and !empty(nearby) and time = try_to_interact {
			// chose a person to interact with
			
			if flip(interaction_chance) {
				// can already have a target
				target <- nearby[rnd(length(nearby) - 1)] as Guest;
				//write name + " tries to interact with " + target;
				do do_interaction;
				
			}
			
			try_to_interact <- try_to_interact + 5.0;
			
		}
		
		if try_to_interact < time {
			try_to_interact <- time + rnd(5,10);
		}
		
	}
	
	reflex debug_print {
		//write name + " loudness: " + loudness;
	}
	
	reflex dancing when: time <= danceTimer{
		color <- rnd_color(255);
		happiness <- happiness + 0.1;
		if(danceTimer = time){
			write name + " stopped dancing";
			color <- baseColor;
			busy <- false;
		}
	}
	
	reflex talking when: time <= talkTime{
		Guest t <- target as Guest;
		if (t.loudness <= loudness) {
			happiness <- happiness + 0.3;
		} else {
			happiness <- happiness - 0.1;
		}
		if(talkTime = time){
			write name + " stopped talking";
			target <- nil;
			busy <- false;
		}
	}
	
	action do_interaction virtual: true;
	
	aspect base {
		draw triangle(guest_shoulder_length) color: color rotate: heading + 90;
	}
}

species Introvert parent: Guest {
	init {
		loudness <- 0.0;
		generosity <- rnd(1.0);
		baseColor <- rgb("blue");
		color <- baseColor;
		interaction_chance <- 0.2;
		nearby_people_limit <- 11;
		
	}
	
	action do_interaction {
		Guest t <- target as Guest;
		// start a conversation 
		busy <- true;
		do start_conversation to: [target] protocol: 'no-protocol' performative: 'propose' contents: ["Do you want to talk?"];
		
	}
	
	reflex receive_answer when: !empty(informs){
		loop proposaltest over: informs{	
			switch(proposaltest.contents[0] as string){
				// introvert receive answers
				match "Yes let's talk"{
					write name + " receives answer yes";
					talkTime <- time + 10.0;
					do end_conversation message: proposaltest contents: ["end"];
				}
				match "No, thank you, I am busy"{
					happiness <- happiness - 0.1;
					
					write name + " receives answer no";
					
					busy <- false;
					target <- nil;
					do end_conversation message: proposaltest contents: ["end"];
				}
			}
		}
		write name + " answer informs " +informs;
	
	}
}

species Extrovert parent: Guest {
	init {
		loudness <- 50.0;
		generosity <- 0.8;
		baseColor <- rgb("red");
		color <- baseColor;
		
	}


	action do_interaction {
		// if they are feeling generous and have money try buying a drink
		if currentLocation = "Bar" and flip(generosity) and money >= 1.0 {
			//TODO: add charisma system?
			Bar b <- Bar[rnd(length(Bar)-1)];
			write name + " ask " + target + " for a drink";
			busy <- true;
			do start_conversation to: [target] protocol: 'no-protocol' performative: 'propose' contents: ["Do you want a drink?", b];			// ask if they want drink
			
		}
		else {
			target <- nil;
		}
	}
	
	reflex receive_answer when: !empty(informs){
		loop proposaltest over: informs{
			string s <- proposaltest.contents[0] as string;
	
			switch(s){
				// extrovert receive answers
				match "Yes please, I want a drink."{
					happiness <- happiness + 0.5;
					write name + " receives answer 'Yes I want drink";
					Guest sender <- proposaltest.sender as Guest;
					Bar targetBar <- proposaltest.contents[1] as Bar;
									
					if location distance_to(targetBar) > 5{
						sender.target <- targetBar;
						target <- targetBar;
					}
					else{
						write(name + " buys drink for " + sender.name);
						money <- money - 1;
						targetBar.money <- targetBar.money + 1;
						sender.loudness <- sender.loudness + 1;
						target <- nil;
						sender.target <- nil;
						busy <- false;
						sender.busy <- false;
					}
					do end_conversation message: proposaltest contents: ["end"];
					
				}
				match "No, thank you, I don't want a drink." {
					happiness <- happiness - 0.1;
					
					write name + " receives answer 'No I don't want drink'";
					target <- nil;
					busy <- false;
					do end_conversation message: proposaltest contents: ["end"];
					
				}
			}
		}
	
	}
}

species Dancer parent: Guest{
	init{
		loudness <- 40.0;
		generosity <- rnd(0.0, 0.7);
		baseColor <- rgb("pink");
		color <- baseColor;
		danceChance <- rnd(0.75, 1.0);
	}
	action do_interaction{
		//Ask "do you want to dance" interaction. 
		//starts by already dancing and inviting in :P 
		if(flip(danceChance)){
			write name + " starting to dance";
			busy <- true;
			danceTimer <- time + 20.0;
			do start_conversation to: [target] protocol: 'no-protocol' performative: 'propose' contents: ["Do you want to dance?", Bar[0]];
			target <- nil;
		
		}
		
	}
}


experiment my_test type: gui {
	output {
		display basic {
			species Introvert aspect:base;
			species Extrovert aspect:base;
			species Bar aspect:base;
			species FoodCourt aspect:base;
			species Dancer aspect:base;
			
			
		}
		
		display charts {
			chart "Guest spent" {
				data "Guest total spent money " value: sum((agents of_generic_species Guest) collect (each.startMoney - each.money));
			}
			
			
		}
		
		display graph {
			chart "Guest happiness" type: histogram {
				loop g over: (agents of_generic_species Guest) {
					data g.name value: g.happiness color: g.color;
				}
			}
		}
	}
}