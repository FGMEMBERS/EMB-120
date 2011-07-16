#######################################################
# PRESTES Hangar - 2011 - January 29, 2011 01:01:54 AM  
#######################################################

# 888888 8b    d8 88""Yb 88""Yb    db    888888 88""Yb 
# 88__   88b  d88 88__dP 88__dP   dPYb   88__   88__dP 
# 88""   88YbdP88 88""Yb 88"Yb   dP__Yb  88""   88"Yb  
# 888888 88 YY 88 88oodP 88  Yb dP""""Yb 888888 88  Yb 
#
# 888888 8b    d8 88""Yb            .d oP"Yb.  dP"Yb  
# 88__   88b  d88 88__dP ________ .d88 "' dP' dP   Yb 
# 88""   88YbdP88 88""Yb """"""""   88   dP'  Yb   dP 
# 888888 88 YY 88 88oodP            88 .d8888  YbodP  
# ________ ________ ________ ________ ________ ________
# """""""" """""""" """""""" """""""" """""""" """"""""

# Author : Isaias V. Prestes
# Notes : 
# LICENSE : GNU-GPL v.3
#
# Revisions : 
#                0.0.1
#                
#                
#                

# Define the base for Hydraulic system
var system_hdry_psi = props.globals.initNode("systems/hydraulics/system-psi",0);
var system_hdry_bar = props.globals.initNode("systems/hydraulics/system-bar",0);
var system_hdry_toqtyltr = props.globals.initNode("systems/hydraulics/total-fluid-qty-liters", 11.35623534);
var system_hdry_toqtygal = props.globals.initNode("systems/hydraulics/total-fluid-qty-gals", 3);


#######################################################
# Hydraulic System Class
#######################################################
var HydraulicSystem = {
	new: func(system,numeng){
		m = { parents : [HydraulicSystem]};
		
			m.systemengine_node = props.globals.getNode("engines/engine[" ~ numeng ~ "]",1);
			
			m.system_hyd_n = props.globals.getNode(system,1);
			
			m.engine_pump = m.system_hyd_n.initNode("engine-pump",0,"BOOL");
			m.eletric_pump = m.system_hyd_n.initNode("electric-pump",0,"BOOL");
			m.system_psi = m.system_hyd_n.initNode("system-psi",0);
			m.system_bar = m.system_hyd_n.initNode("system-bar",0);
			m.fluid_qty_liters = m.system_hyd_n.initNode("fluid-qty-liters", 11.35623534);
			m.fluid_qty_gals = m.system_hyd_n.initNode("fluid-qty-gals", 3);
			m.engine_pump_fail = m.system_hyd_n.initNode("engine-pump-failure",0,"BOOL");
			m.engine_epump_fail = m.system_hyd_n.initNode("electric-pump-failure",0,"BOOL");
		
			m.mirrosyasim_pump_psi = props.globals.getNode("systems/hydraulics/pump-psi[" ~ numeng ~ "]", 1);
		
		return m;
	},
	
	on_engine: func{
		var engine_status = me.systemengine_node.getNode("running",1).getValue();
		
		if ( engine_status and !me.engine_pump.getValue() ) {
			me.engine_pump.setBoolValue(1);
			interpolate(me.system_psi.getPath(), 2500, 15);
		};
		
	},
	
	on_eletric: func {
		var electrical_status = props.globals.getNode("systems/electrical/bus-volts",1).getValue();
		
		if ( electrical_status >= 24.0 and !me.eletric_pump.getValue() ) {
			me.eletric_pump.setBoolValue(1);
			interpolate(me.system_psi.getPath(), 2500, 19);
		};
		
	},
	
	off_engine: func {
		
		if ( me.system_psi.getValue() > 0 and me.engine_pump.getValue() ) {
			me.engine_pump.setBoolValue(0);
			if (!me.eletric_pump.getValue() ) {
				interpolate(me.system_psi.getPath(), 0, 15) ;
			}
		};

	},
	
	off_electrical: func {
		
		if ( m.system_psi.getValue() > 0 and m.eletric_pump.getValue() ) {
			me.eletric_pump.setBoolValue(0);
			if (!me.engine_pump.getValue() ) {
				interpolate(me.system_psi.getPath(), 0, 15) ;
			}
		};

	},

	update: func {
		var system_psi_value = props.globals.getNode("systems/hydraulics/system-psi",1).getValue();
		var valor = me.system_psi.getValue();
		
		me.mirrosyasim_pump_psi = me.system_psi.getValue();
		me.system_bar.setValue( valor * 0.068947 );
		
	}	
	
};


# Function for system update
var Update_HydraulicSystem = func {
	var hydraulicsystems = props.globals.getNode("systems/hydraulics",1).getChildren("system");
	var system_psi_value = 0.0 ;
	var total_fluid_qty_gals = 0.0 ;
	
	foreach (var reg; hydraulicsystems) {
		var valor = reg.getNode("system-psi", 1).getValue();
		var total_fluid_qty_gals = total_fluid_qty_gals + reg.getNode("fluid-qty-gals", 1).getValue();
		if ( valor > system_psi_value ) {
			var system_psi_value = valor;
		};
	} ;	

	setprop("systems/hydraulics/system-psi", system_psi_value );
	setprop("systems/hydraulics/system-bar", system_psi_value * 0.068947 );
	
	var total_fluid_qty_liters = ( total_fluid_qty_gals * 3.78541178 ) ;
	setprop("systems/hydraulics/total-fluid-qty-gals", total_fluid_qty_gals);
	setprop("systems/hydraulics/total-fluid-qty-liters", total_fluid_qty_liters );

	settimer(Update_HydraulicSystem,1);
};

var UpdateHdrSystem = func{
	Hydr0.update() ;
	Hydr1.update() ;
	Hydr2.update() ;
	Hydr3.update() ;
	
	settimer(UpdateHdrSystem, 1);
}

# Create all hydraulic systems (common one per engine)
var Hydr0 = HydraulicSystem.new("systems/hydraulics/system[0]",0);
var Hydr1 = HydraulicSystem.new("systems/hydraulics/system[1]",1);
var Hydr2 = HydraulicSystem.new("systems/hydraulics/system[2]",2);
var Hydr3 = HydraulicSystem.new("systems/hydraulics/system[3]",3);

# Set the system update
setlistener("/sim/signals/fdm-initialized", func {
    settimer(UpdateHdrSystem,1);
	settimer(Update_HydraulicSystem(), 1);
});

