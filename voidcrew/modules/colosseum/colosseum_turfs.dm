/// Arena sand has no buried wildlife for explosions or fishing rods to uncover.
/turf/open/misc/beach/sand/colosseum
	desc = "Dry arena sand, raked smooth between bouts."
	baseturfs = /turf/open/misc/beach/sand/colosseum

/turf/open/misc/beach/sand/colosseum/Initialize(mapload)
	. = ..()
	remove_lazy_fishing()

/// Temporary arena hazards must not bring Lavaland's fish into the venue.
/turf/open/lava/smooth/colosseum
	baseturfs = /turf/open/lava/smooth/colosseum
	fish_source_type = null
