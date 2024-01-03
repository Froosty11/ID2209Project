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


global {
	init {
		create Bar;
		create Introvert with: (target: nil);
		create Extrovert with: (target: Introvert[0]);
		create Dancer with: (target: Introvert[0]);
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
	rgb color;
	rgb baseColor;
	agent target;
	float interaction_chance <- 1.0;
	float try_to_interact <- 1.0;
	float danceChance <- rnd(1.0);
	int danceTimer <- 0;
	
	reflex move when: target != nil {
		do goto target:target;
		
		if location distance_to(target) < 1 {
			target <- nil;
		}
	}
	reflex dancing when: danceTimer != 0{
		danceTimer <- danceTimer - 1;
		color <- rnd_color(255);
		if(danceTimer = 0){
			color <- baseColor;
		}
	}
	reflex wander when: target = nil {
		do wander;
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
					if(flip(generosity)){ 
						do inform message: proposaltest contents: ["Yes please, I want a drink.", targetBar];
					}
					else{
						do inform message: proposaltest contents: ["No, thank you, I don't want a drink.", targetBar];
					}
				}
				match "Yes please, I want a drink."{					
					if 5 < location distance_to(targetBar.location){
						sender.target <- targetBar;
						target <- targetBar;
					}
					else{
						write(name + "buys drink for" + sender.name);
						money <- money - 1;
						targetBar.money <- targetBar.money + 1;
						sender.loudness <- sender.loudness + 1;
					}
				}
				match "Do you want to dance?"{
					if(flip(danceChance)){
						write(name + "joins in dancing with " + sender.name);
						danceTimer <- 50;
						target <- nil;
					}
				}
			}
			
		}
	}
	reflex interact {
		list<agent> nearby <- (agents of_generic_species Guest) at_distance(5);
		
		// if the agent doesnt have a target and there is a
		if target = nil and !empty(nearby) and time = try_to_interact {
			// chose a person to interact with
			
			if flip(interaction_chance) {
				// can already have a target
				target <- nearby[0] as Guest;
				do do_interaction;
				
			}
			
			try_to_interact <- try_to_interact + 5.0;
			
		}
		
		if try_to_interact < time {
			try_to_interact <- try_to_interact + 5.0;
		}
		
		//write (agents of_generic_species Guest) at_distance(5);
	}
	
	reflex debug_print {
		write name + " loudness: " + loudness;
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
		color <- rgb("blue");
		baseColor <- color;
	}
	
	action do_interaction {
		
		//TODO: Add possible introvert interaction? 
	}
}

species Extrovert parent: Guest {
	init {
		loudness <- 0.0;
		generosity <- 0.8;
		color <- rgb("red");
		baseColor <- color;
	}
	action do_interaction {
		// if they are feeling generous and have money try buying a drink
		if flip(generosity) and money >= 1.0 {
			//TODO: add charisma system?
			Bar b <- Bar[rnd(length(Bar)-1)];
			do start_conversation to: [target] protocol: 'no-protocol' performative: 'inform' contents: ["Do you want a drink?", b];			// ask if they want drink
		}
	}
}

species Dancer parent: Guest{
	init{
		loudness <- 4.0;
		generosity <- rnd(0.0, 0.7);
		color <- rgb("pink");
		baseColor <- color;
		danceChance <- rnd(0.75, 1.0);
	}
	action do_interaction{
		//Ask "do you want to dance" interaction. 
		//starts by already dancing and inviting in :P 
		if(flip(danceChance)){
			danceTimer <- 100;
			do start_conversation to: [target] protocol: 'no-protocol' performative: 'inform' contents: ["Do you want to dance?", Bar[0]];			// ask if they wanna dance
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
			species Dancer aspect:base;
			
		}
	}
}