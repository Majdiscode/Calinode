//
//  UpdatedPullTreeData.swift
//  TestCaliNode
//
//  NEW UNLOCK LOGIC - Prerequisites to unlock next skill
//

import Foundation
import SwiftUI

let enhancedPullTreeV1 = EnhancedSkillTreeModel(
    id: "pull",
    name: "Pull Tree",
    version: 1,
    
    // FOUNDATIONAL SKILLS
    foundationalSkills: [
        SkillNode(
            id: "deadHang",
            label: "🪢",
            fullLabel: "Dead Hang (30s)",
            tree: "pull",
            requires: [],
            variationLevel: 0,
            version: 1,
            confirmPrompt: "Can you dead hang for 5 seconds?", // ✅ Easy entry requirement
            unlocked: false,
            masteryLevel: 0,
            logHistory: []
        ),
        SkillNode(
            id: "scapularPulls",
            label: "⬇️",
            fullLabel: "Scapular Pulls (2x8)",
            tree: "pull",
            requires: ["deadHang"],
            variationLevel: 0,
            version: 1,
            confirmPrompt: "Can you dead hang for 30 seconds?", // ✅ Prerequisite: strong dead hang
            unlocked: false,
            masteryLevel: nil,
            logHistory: []
        ),
        SkillNode(
            id: "negativePullUp",
            label: "⬇️💪",
            fullLabel: "Negative Pull-Up (3x5s)",
            tree: "pull",
            requires: ["scapularPulls"],
            variationLevel: 0,
            version: 1,
            confirmPrompt: "Can you do 2 sets of 6 scapular pulls?", // ✅ Prerequisite: solid scapular strength
            unlocked: false,
            masteryLevel: nil,
            logHistory: []
        ),
        SkillNode(
            id: "bandAssistedPullUp",
            label: "🟡🆙",
            fullLabel: "Band Assisted Pull-Up (2x6)",
            tree: "pull",
            requires: ["negativePullUp"],
            variationLevel: 0,
            version: 1,
            confirmPrompt: "Can you do 3 negative pull-ups with 5-second descents?", // ✅ Prerequisite: controlled negatives
            unlocked: false,
            masteryLevel: nil,
            logHistory: []
        ),
        SkillNode(
            id: "pullUp",
            label: "🆙",
            fullLabel: "Pull-Up (2x5)",
            tree: "pull",
            requires: ["bandAssistedPullUp"],
            variationLevel: 0,
            version: 1,
            confirmPrompt: "Can you do 2 sets of 5 band assisted pull-ups?", // ✅ Prerequisite: assisted strength
            unlocked: false,
            masteryLevel: nil,
            logHistory: []
        )
    ],
    
    foundationalPositions: [
        "deadHang": CGPoint(x: 200, y: 1000),
        "scapularPulls": CGPoint(x: 200, y: 850),
        "negativePullUp": CGPoint(x: 200, y: 700),
        "bandAssistedPullUp": CGPoint(x: 200, y: 550),
        "pullUp": CGPoint(x: 200, y: 400)
    ],
    
    // SPECIALIZED BRANCHES
    branches: [
        // EXPLOSIVE BRANCH
        SkillBranch(
            id: "explosive",
            name: "Explosive",
            description: "Power and speed",
            color: "#FF6B35",
            skills: [
                SkillNode(
                    id: "chestTouchPullup",
                    label: "💥",
                    fullLabel: "Chest-to-Bar Pull-up (2x3)",
                    tree: "pull",
                    requires: ["pullUp"],
                    variationLevel: 1,
                    version: 1,
                    confirmPrompt: "Can you do 2 sets of 8 pull-ups?", // ✅ Prerequisite: solid pull-up volume
                    unlocked: false,
                    masteryLevel: nil,
                    logHistory: []
                ),
                SkillNode(
                    id: "muscleUp",
                    label: "💪",
                    fullLabel: "Muscle-Up (1x1)",
                    tree: "pull",
                    requires: ["chestTouchPullup"],
                    variationLevel: 2,
                    version: 1,
                    confirmPrompt: "Can you do 2 sets of 3 chest-to-bar pull-ups?", // ✅ Prerequisite: explosive pulling power
                    unlocked: false,
                    masteryLevel: nil,
                    logHistory: []
                )
            ],
            positions: [
                "chestTouchPullup": CGPoint(x: 60, y: 250),
                "muscleUp": CGPoint(x: 60, y: 100)
            ]
        ),
        
        // ISOMETRIC HOLDS BRANCH
        SkillBranch(
            id: "isometric",
            name: "Isometric",
            description: "Static strength",
            color: "#4ECDC4",
            skills: [
                SkillNode(
                    id: "flexedHang",
                    label: "💎",
                    fullLabel: "Flexed Arm Hang (15s)",
                    tree: "pull",
                    requires: ["pullUp"],
                    variationLevel: 1,
                    version: 1,
                    confirmPrompt: "Can you do 2 sets of 8 pull-ups?", // ✅ Prerequisite: pulling endurance
                    unlocked: false,
                    masteryLevel: nil,
                    logHistory: []
                ),
                SkillNode(
                    id: "frontLeverTuck",
                    label: "🦅",
                    fullLabel: "Front Lever Tuck (8s)",
                    tree: "pull",
                    requires: ["flexedHang"],
                    variationLevel: 2,
                    version: 1,
                    confirmPrompt: "Can you hold a flexed arm hang for 15 seconds?", // ✅ Prerequisite: isometric hold strength
                    unlocked: false,
                    masteryLevel: nil,
                    logHistory: []
                ),
                SkillNode(
                    id: "frontLever",
                    label: "🦅",
                    fullLabel: "Front Lever (5s)",
                    tree: "pull",
                    requires: ["frontLeverTuck"],
                    variationLevel: 3,
                    version: 1,
                    confirmPrompt: "Can you hold a front lever tuck for 8 seconds?", // ✅ Prerequisite: tuck progression
                    unlocked: false,
                    masteryLevel: nil,
                    logHistory: []
                )
            ],
            positions: [
                "flexedHang": CGPoint(x: 200, y: 250),
                "frontLeverTuck": CGPoint(x: 200, y: 150),
                "frontLever": CGPoint(x: 200, y: 50)
            ]
        ),
        
        // UNILATERAL BRANCH
        SkillBranch(
            id: "unilateral",
            name: "Unilateral",
            description: "Single-arm strength",
            color: "#A8E6CF",
            skills: [
                SkillNode(
                    id: "archerPullup",
                    label: "🏹",
                    fullLabel: "Archer Pull-Up (2x3)",
                    tree: "pull",
                    requires: ["pullUp"],
                    variationLevel: 1,
                    version: 1,
                    confirmPrompt: "Can you do 2 sets of 10 pull-ups?", // ✅ Prerequisite: high volume pulling
                    unlocked: false,
                    masteryLevel: nil,
                    logHistory: []
                ),
                SkillNode(
                    id: "oneArmPullup",
                    label: "☝️",
                    fullLabel: "One-Arm Pull-up (1x1)",
                    tree: "pull",
                    requires: ["archerPullup"],
                    variationLevel: 2,
                    version: 1,
                    confirmPrompt: "Can you do 2 sets of 5 archer pull-ups per side?", // ✅ Prerequisite: unilateral progression
                    unlocked: false,
                    masteryLevel: nil,
                    logHistory: []
                )
            ],
            positions: [
                "archerPullup": CGPoint(x: 340, y: 250),
                "oneArmPullup": CGPoint(x: 340, y: 120)
            ]
        )
    ],
    
    // MASTER SKILLS - COMPLETELY EMPTY NOW
    masterSkills: [],
    
    masterPositions: [:]
)
