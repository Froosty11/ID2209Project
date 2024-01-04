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
	init {
		create Bar;
		create FoodCourt;
		create Dancer;
		create Introvert;
		create Extrovert;
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


species Guest skills: [moving, fipa]{
	float generosity;
	float money <- 100.0;
	float loudness;
	bool busy <- false;
	rgb color;
	rgb baseColor;
	agent target;
	float interaction_chance <- 1.0;
	float try_to_interact <- 1.0;
	float hunger <- 0.0;
	string currentLocation;
	
	float danceChance <- rnd(1.0);
	float danceTimer <- -1.0;
	
	reflex move when: target != nil {
		do goto target:target;
		
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
	}
	
	reflex wander when: target = nil {
		do wander;
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
		else if hunger = 0.0 and !busy {
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
	
	reflex respond_to_proposal when: !empty(informs){
		loop proposaltest over: informs{
			string s <- proposaltest.contents[0] as string;
			Guest sender <- proposaltest.sender as Guest;
			Bar targetBar <- proposaltest.contents[1] as Bar;
			
			
			switch(s){
				match "Do you want a drink?"{
					//Switch case 1: Being asked out for a drink?
					//Respond to sender
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
			}
			
		}
	}
	reflex interact {
		list<agent> nearby <- (agents of_generic_species Guest) at_distance(5);
		
		// if the agent doesnt have a target and there is a
		if !busy and !empty(nearby) and time = try_to_interact {
			// chose a person to interact with
			
			if flip(interaction_chance) {
				// can already have a target
				target <- nearby[rnd(length(nearby) - 1)] as Guest;
				write name + " tries to interact with " + target;
				do do_interaction;
				
			}
			
			try_to_interact <- try_to_interact + 5.0;
			
		}
		
		if try_to_interact < time {
			try_to_interact <- time + 5.0;
		}
		
		//write (agents of_generic_species Guest) at_distance(5);
	}
	
	reflex debug_print {
		//write name + " loudness: " + loudness;
	}
	
	reflex dancing when: time <= danceTimer{
		color <- rnd_color(255);
		if(danceTimer = time){
			write name + " stopped dancing";
			color <- baseColor;
			busy <- false;
		}
	}
	
	action do_interaction virtual: true;
	
	aspect base {
		draw circle(1) color: color;
	}
}

species Introvert parent: Guest {
	init {
		loudness <- 0.0;
		generosity <- rnd(1.0);
		baseColor <- rgb("blue");
		color <- baseColor;
		
	}
	
	action do_interaction {
		
		target <- nil;
		busy <- false;
	}
}

species Extrovert parent: Guest {
	init {
		loudness <- 0.0;
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
			do start_conversation to: [target] protocol: 'no-protocol' performative: 'inform' contents: ["Do you want a drink?", b];			// ask if they want drink
			
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
		loudness <- 4.0;
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
			do start_conversation to: [target] protocol: 'no-protocol' performative: 'inform' contents: ["Do you want to dance?", Bar[0]];
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
				float totalMoney <- sum((agents of_generic_species Guest) collect (each.money));
				data "Total money " value: totalMoney;
				
			}
		
		}
	}
}