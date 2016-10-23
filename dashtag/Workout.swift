//
//  Workout.swift
//  dashtag
//
//  Created by Bao Vu on 10/23/16.
//  Copyright © 2016 Dashtag. All rights reserved.
//

struct Workout {
    var name: String
    var instructions: String
    var reps: Int
    var sets: Int
    var time: Int
    
    init(name: String, instructions: String, reps: Int, sets: Int, time: Int) {
        self.name = name
        self.instructions = instructions
        self.reps = reps
        self.sets = sets
        self.time = time
    }
}
