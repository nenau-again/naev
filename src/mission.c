/*
 * See Licensing and Copyright notice in naev.h
 */


#include "mission.h"

#include <string.h>
#include <malloc.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "naev.h"
#include "log.h"




/*
 * current player missions
 */
Mission player_missions[MISSION_MAX];


/*
 * mission stack
 */
//static Mission *mission_stack = NULL; /* unmuteable after creation */
//static int mission_nstack = 0;


/*
 * prototypes
 */
/* extern */
extern int misn_run( Mission *misn, char *func );



/*
 * creates a mission
 */
int mission_create( MissionData* misn )
{
	int i;

	/* find last mission */
	for (i=0; i<MISSION_MAX; i++)
		if (player_missions[i].data == NULL) break;
	
	/* no missions left */
	if (i>=MISSION_MAX) return -1;


	player_missions[i].data = misn;

	/* init lua */
	player_missions[i].L = luaL_newstate();
	luaopen_string( player_missions[i].L ); /* string.format can be very useful */
	misn_loadLibs( player_missions[i].L ); /* load our custom libraries */

	return 0;
}


/*
 * load/free
 */
int missions_load (void)
{
#if 0
	yaml_parser_t parser;
	yaml_event_t input_event;

	memset(&parser, 0, sizeof(parser));
	memset(&input_event, 0, sizeof(input_event));

	/* set up parser */
	if (!yaml_parser_initialize(&parser)) {
		ERR("Could not initialize the parser object!");
		return -1;
	}
	yaml_parser_set_input_file(&parser, stdin);

	/* cleanup */
	yaml_event_delete(&input_event);
	yaml_parser_delete(&parser);
#endif

	return 0;
}
void missions_free (void)
{
}




