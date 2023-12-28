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
		create Introvert;
		create Extrovert;
	}
	
}


species Guest skills: [moving, fipa]{
	float generosity;
	float money <- 100.0;
	float loudness;
	rgb color;
	Guest target;
	float interaction_chance <- 1.0;
	
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
		
		if target = nil and !empty(nearby) {
			// chose a person to interact with
			
			if flip(interaction_chance) {
				// can already have a target
				target <- nearby[0] as Guest;
				do do_interaction;
			}
			
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
		
		// ask if they want drink
		ask target{
			
			// if they are feeling generous and have money try buying a drink
			if flip(generosity) and money >= 1.0 {
				// buying a drink for target
				write  myself.name + " buying a drink for " + self.name;
				myself.money <- myself.money - 1.0;
				self.loudness <- self.loudness + 1.0;
			}
		}
	}
}


experiment my_test type: gui {
	output {
		display basic {
			species Introvert aspect:base;
			species Extrovert aspect:base;
			
		}
	}
}