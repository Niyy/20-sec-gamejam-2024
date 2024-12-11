# Tile Data Flow

On an effect of one tile it will benefit all other tiles and units on the map
to decimnate that data to other tiles. Both pathing and what a pawn can and
will want to do. Is the pawn hungry were can it get food. Is the pawn on a 
quest? He may be more adventures than a merchant who just wants to get to the
next walled city. These decisions will be made simplier if we can alert pawns
to these things.

## Tile Memory

When pawns travel upon a tile they can leave a tile memory such as where was 
this pawn moving to? This can also be utilized in a knowledge system based on
what traveled, how many, were they wearing heavey armor?

X < Start 5, 5
 X < I know I can get to 5, 5 and I can get to target 
 X < I know I can get to 5, 5 and I can get to target 
 X < I know I can get to 5, 5 and I can get to target 
  X < Target

Also we can flood the map with useful info for pawns to act on. Nearest city? My
tile could see the smoke rising on the horizon or these are well traveled paths.
This can all be stored on tiles using info gates such as pawn origin. They are
from this region and now it intemently.

## Relationships

Rela
