extends Node2D

var playerBody: CharacterBody2D
var respawn_point = null
var players_swapped: bool = false

# ADD THIS: A list to remember which enemies have been killed
var dead_enemies: Array = []
