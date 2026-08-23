//
//  Exercise+Classification.swift
//  Forge
//
//  Rough compound vs isolation classification, used to pick the rest-timer
//  duration. Multi-joint (compound) lifts recruit several muscles, so they
//  carry two or more secondary muscles in the seed data; single-joint
//  (isolation) moves have zero or one. It's a heuristic — good enough to pick
//  a rest length, and swappable for an explicit per-exercise flag later.
//

import Foundation

extension Exercise {
    var isCompound: Bool { secondaryMuscles.count >= 2 }
}
