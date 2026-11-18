//#define LOWMEMORYMODE //uncomment this to load centcom and runtime station and thats it.

// VOIDCREW EDIT START: SOLARIUM - the public build must not require the asset submodule.
#ifdef HORUSHERESY
#include "..\Horusheresy\_maps\CentCom.dmm"
#else
#include "map_files\generic\CentCom.dmm"
#endif
// VOIDCREW EDIT END: SOLARIUM

#ifndef LOWMEMORYMODE
	#ifdef ALL_MAPS
		#include "map_files\debug\multiz.dmm"
		#include "map_files\debug\runtimestation.dmm"
		#include "map_files\Deltastation\DeltaStation2.dmm"
		#include "map_files\IceBoxStation\IceBoxStation.dmm"
		#include "map_files\MetaStation\MetaStation.dmm"
		#include "map_files\Mining\Lavaland.dmm"
		#include "map_files\tramstation\tramstation.dmm"
		#include "map_files\CatwalkStation\CatwalkStation_2023.dmm"
		#include "map_files\NebulaStation\NebulaStation.dmm"
		#include "map_files\wawastation\wawastation.dmm"
	#endif
	#ifdef ALL_TEMPLATES
		#include "templates.dm"
	#endif
#endif
