/**
* Name: finalproject
* Based on the internal empty template. 
* Author: andreaslevander
* Tags: 
*/


model finalproject

/* Insert your model definition here */


global {
	init {
		create Bar;
		
		create Introvert with: (target: Bar[0]);
		create Extrovert with: (target: Bar[0]);
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
	agent target;
	float interaction_chance <- 1.0;
	float try_to_interact <- 1.0;
	
	reflex move when: target != nil {
		do goto target:target;
		
		if location distance_to(target) < 1 {
			target <- nil;
		}
	}
	
	reflex wander when: target = nil {
		do wander;
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
	}
	
	action do_interaction {
		
		write "do interaction";
	}
}

species Extrovert parent: Guest {
	init {
		loudness <- 0.0;
		generosity <- 0.8;
		color <- rgb("red");
	}
	
	action do_interaction {
		
		// if they are feeling generous and have money try buying a drink
		if flip(generosity) and money >= 1.0 {
				
			// ask if they want drink
			ask target as Guest{
				// buying a drink for target
				write  myself.name + " buying a drink for " + self.name;
			
				self.target <- Bar[0];
				myself.target <- Bar[0];
				
				myself.money <- myself.money - 1.0;
				self.loudness <- self.loudness + 1.0;
				Bar[0].money <- Bar[0].money + 1.0;
					
			}
		}
	}
}


experiment my_test type: gui {
	output {
		display basic {
			species Introvert aspect:base;
			species Extrovert aspect:base;
			species Bar aspect:base;
			
		}
	}
}