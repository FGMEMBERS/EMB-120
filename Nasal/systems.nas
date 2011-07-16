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

# Author : Isaías V. Prestes
# Notes : Based on Syd Adams system for Boeing 777 and adjusted for my aircrafts.
# LICENSE : GNU-GPL v.2
#
# Revisions : 
#                0.0.1
#                

#######################################################
# Engine control class
#######################################################
# Exemplo: var Eng = Engine.new(engine number);
var Engine = {
    new : func(eng_num){
        m = { parents : [Engine]};
        m.fdensity = getprop("consumables/fuel/tank/density-ppg");
        if(m.fdensity ==nil)m.fdensity=6.72;
        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
        m.running = m.eng.getNode("running",1);
        m.running.setBoolValue(0);
        m.n1 = m.eng.getNode("n1",1);
        m.n2 = m.eng.getNode("n2",1);
        m.rpm = m.eng.getNode("rpm",1);
        m.rpm.setDoubleValue(0);
        m.throttle_lever = props.globals.getNode("controls/engines/engine["~eng_num~"]/throttle-lever",1);
        m.throttle_lever.setDoubleValue(0);
        m.throttle = props.globals.getNode("controls/engines/engine["~eng_num~"]/throttle",1);
        m.throttle.setDoubleValue(0);
        m.cutoff = props.globals.getNode("controls/engines/engine["~eng_num~"]/cutoff",1);
        m.cutoff.setBoolValue(1);
        m.fuel_out = props.globals.getNode("engines/engine["~eng_num~"]/out-of-fuel",1);
        m.fuel_out.setBoolValue(0);
        m.starter = props.globals.getNode("controls/engines/engine["~eng_num~"]/starter",1);
        m.fuel_pph=m.eng.getNode("fuel-flow_pph",1);
        m.fuel_pph.setDoubleValue(0);
        m.fuel_gph=m.eng.getNode("fuel-flow-gph",1);
        m.hpump=props.globals.getNode("systems/hydraulics/pump-psi["~eng_num~"]",1);
        m.hpump.setDoubleValue(0);
    return m;
    },
	#### update ####
    update : func{
        if(me.fuel_out.getBoolValue())me.cutoff.setBoolValue(1);
        if(!me.cutoff.getBoolValue()){
        me.rpm.setValue(me.n1.getValue());
        me.throttle_lever.setValue(me.throttle.getValue());
        }else{
            me.throttle_lever.setValue(0);
            if(me.starter.getBoolValue()){
                me.spool_up();
            }else{
                var tmprpm = me.rpm.getValue();
                if(tmprpm > 0.0){
                    tmprpm -= getprop("sim/time/delta-realtime-sec") * 0.5;
                    me.rpm.setValue(tmprpm);
                }
            }
        }
    me.fuel_pph.setValue(me.fuel_gph.getValue()*me.fdensity);
    var hpsi =me.rpm.getValue();
    if(hpsi>60)hpsi = 60;
    me.hpump.setValue(hpsi);
    },

    spool_up : func{
        if(!me.cutoff.getBoolValue()){
        return;
        }else{
            var tmprpm = me.rpm.getValue();
            tmprpm += getprop("sim/time/delta-realtime-sec") * 0.5;
            me.rpm.setValue(tmprpm);
            if(tmprpm >= me.n1.getValue())me.cutoff.setBoolValue(0);
        }
    },

};

#######################################################
# Stall horn 
#######################################################

var limitstallhornL = props.globals.initNode("/limits/stall-speedL", 100.0);
var limitstallhornM = props.globals.initNode("/limits/stall-speedM", 120.0);
var limitstallhornU = props.globals.initNode("/limits/stall-speedU", 150.0);

stall_horn = func{
    var alert = 0;
    var kias = getprop("velocities/airspeed-kt");
	
	var limitspd1 = getprop("/limits/stall-speedL");
	var limitspd2 = getprop("/limits/stall-speedM");
	var limitspd3 = getprop("/limits/stall-speedU");

    if( kias > limitspd3 ){
		setprop("sim/sound/stall-horn",alert);return;};
		var wow1 = getprop("gear/gear[1]/wow");
		var wow2 = getprop("gear/gear[2]/wow");
    if(!wow1 or !wow2){
        var grdn = getprop("controls/gear/gear-down");
        var flap = getprop("controls/flight/flaps");
        if( kias < limitspd1 ){
            alert = 1;
        } elsif( kias < limitspd2 ){
            if(!grdn ) alert = 1;
        } else {
            if( flap == 0 ) alert = 1;
        }
    }
    setprop("sim/sound/stall-horn", alert);
}


#######################################################
# Aircraft Startup
#######################################################
var Startup = func {
	setprop("controls/electric/engine[0]/master-alt",1);
	setprop("controls/electric/engine[1]/master-alt",1);
	setprop("controls/electric/engine[0]/generator",1);
	setprop("controls/electric/engine[1]/generator",1);
	setprop("controls/electric/engine[0]/bus-tie",1);
	setprop("controls/electric/engine[1]/bus-tie",1);
	setprop("controls/electric/avionics-switch",1);
	setprop("controls/electric/battery-switch",1);
	setprop("controls/electric/inverter-switch",1);
	setprop("controls/lighting/instrument-norm",0.8);
	setprop("controls/lighting/nav-lights",1);
	setprop("controls/lighting/beacon",1);
	setprop("controls/lighting/strobe",1);
	setprop("controls/lighting/wing-lights",1);
	setprop("controls/lighting/taxi-lights",1);
	setprop("controls/lighting/logo-lights",1);
	setprop("controls/lighting/cabin-lights",1);
	setprop("controls/lighting/landing-lights",1);
	setprop("controls/engines/engine[0]/cutoff",0);
	setprop("controls/engines/engine[1]/cutoff",0);
	setprop("controls/fuel/tank/boost-pump",1);
	setprop("controls/fuel/tank/boost-pump[1]",1);
	setprop("controls/fuel/tank[1]/boost-pump",1);
	setprop("controls/fuel/tank[1]/boost-pump[1]",1);
	setprop("controls/fuel/tank[2]/boost-pump",1);
	setprop("controls/fuel/tank[2]/boost-pump[1]",1);
}

#######################################################
# Aircraft Shutdown
#######################################################
var Shutdown = func {
	setprop("controls/electric/engine[0]/generator",0);
	setprop("controls/electric/engine[1]/generator",0);
	setprop("controls/electric/engine[0]/bus-tie",0);
	setprop("controls/electric/engine[1]/bus-tie",0);
	setprop("controls/electric/avionics-switch",0);
	setprop("controls/electric/battery-switch",0);
	setprop("controls/electric/inverter-switch",0);
	setprop("controls/lighting/instruments-norm",0);
	setprop("controls/lighting/nav-lights",0);
	setprop("controls/lighting/beacon",0);
	setprop("controls/lighting/strobe",0);
	setprop("controls/lighting/wing-lights",0);
	setprop("controls/lighting/taxi-lights",0);
	setprop("controls/lighting/logo-lights",0);
	setprop("controls/lighting/cabin-lights",0);
	setprop("controls/lighting/landing-lights",0);
	setprop("controls/engines/engine[0]/cutoff",1);
	setprop("controls/engines/engine[1]/cutoff",1);
	setprop("controls/fuel/tank/boost-pump",0);
	setprop("controls/fuel/tank/boost-pump[1]",0);
	setprop("controls/fuel/tank[1]/boost-pump",0);
	setprop("controls/fuel/tank[1]/boost-pump[1]",0);
	setprop("controls/fuel/tank[2]/boost-pump",0);
	setprop("controls/fuel/tank[2]/boost-pump[1]",0);
}

#######################################################
# Wiper / Limpadores
#######################################################
var Wiper = {
    new : func {
        m = { parents : [Wiper] };
        m.direction = 0;
        m.delay_count = 0;
        m.spd_factor = 0;
        m.node = props.globals.getNode(arg[0],1);
        m.power = props.globals.getNode(arg[1],1);
        if(m.power.getValue()==nil)m.power.setDoubleValue(0);
        m.spd = m.node.getNode("arc-sec",1);
        if(m.spd.getValue()==nil)m.spd.setDoubleValue(1);
        m.delay = m.node.getNode("delay-sec",1);
        if(m.delay.getValue()==nil)m.delay.setDoubleValue(0);
        m.position = m.node.getNode("position-norm", 1);
        m.position.setDoubleValue(0);
        m.switch = m.node.getNode("switch", 1);
        if (m.switch.getValue() == nil)m.switch.setBoolValue(0);
        return m;
    },
    active: func{
    if(me.power.getValue()<=5)return;
    var spd_factor = 1/me.spd.getValue();
    var pos = me.position.getValue();
    if(!me.switch.getValue()){
        if(pos <= 0.000)return;
        }
    if(pos >=1.000){
        me.direction=-1;
        }elsif(pos <=0.000){
        me.direction=0;
        me.delay_count+=getprop("/sim/time/delta-sec");
        if(me.delay_count >= me.delay.getValue()){
            me.delay_count=0;
            me.direction=1;
            }
        }
    var wiper_time = spd_factor*getprop("/sim/time/delta-sec");
    pos +=(wiper_time * me.direction);
    me.position.setValue(pos);
    }
};

##############################################################
# System Engines On/Off - Controle de Motores ligados/desligados
##############################################################

# Definição das properties
props.globals.initNode("/sim/models/engines/engine[0]/n1", 0.0, "DOUBLE");
props.globals.initNode("/sim/models/engines/engine[0]/n2", 0.0, "DOUBLE");

props.globals.initNode("/sim/models/engines/engine[1]/n1", 0.0, "DOUBLE");
props.globals.initNode("/sim/models/engines/engine[1]/n2", 0.0, "DOUBLE");

props.globals.initNode("/sim/models/engines/engine[0]/rpm", 0.0, "DOUBLE");
props.globals.initNode("/sim/models/engines/engine[1]/rpm", 0.0, "DOUBLE");

props.globals.initNode("/sim/models/engines/engine[0]/fuel-consumed-lbs", 0.0, "DOUBLE");
props.globals.initNode("/sim/models/engines/engine[1]/fuel-consumed-lbs", 0.0, "DOUBLE");

props.globals.initNode("/sim/models/engines/starting", 0, "BOOL");

# Definicoes 
props.globals.initNode("/sim/models/engines/settings/idle-fuel-consumed-lbs", 0.001, "DOUBLE");
props.globals.initNode("/sim/models/engines/settings/idle-n1", 55.0, "DOUBLE");
props.globals.initNode("/sim/models/engines/settings/idle-n2", 70.0, "DOUBLE");
props.globals.initNode("/sim/models/engines/settings/idle-rpm", 50, "DOUBLE");

props.globals.initNode("/sim/models/engines/settings/time_shutdown", 25.0, "DOUBLE");
props.globals.initNode("/sim/models/engines/settings/time_start_n1", 25.0, "DOUBLE");
props.globals.initNode("/sim/models/engines/settings/time_start_n2", 30.0, "DOUBLE");
props.globals.initNode("/sim/models/engines/settings/time_start", getprop("/sim/models/engines/settings/time_start_n2") , "DOUBLE");

setlistener("/sim/model/start-idling", func {
	var idle = props.globals.getNode("/sim/model/start-idling", 1);
    var run = idle.getBoolValue();
	if (!run) {
		print("SISTEMA : Cortados motores... shutdown!");
		
		setprop("controls/engines/engine[0]/throttle", 0);
		setprop("controls/engines/engine[1]/throttle", 0);
				
		setprop("/sim/models/engines/engine[0]/fuel-consumed-lbs",0);
		setprop("/sim/models/engines/engine[1]/fuel-consumed-lbs",0);
		
		setprop("/sim/models/engines/engine[0]/n1", getprop("engines/engine[0]/n1") );
		setprop("/sim/models/engines/engine[0]/n2", getprop("engines/engine[0]/n2") );
		setprop("/sim/models/engines/engine[0]/rpm", getprop("engines/engine[0]/rpm") );
		
	
		setprop("/sim/models/engines/engine[1]/n1", getprop("engines/engine[1]/n1") );
		setprop("/sim/models/engines/engine[1]/n2", getprop("engines/engine[1]/n2") );
		setprop("/sim/models/engines/engine[1]/rpm", getprop("engines/engine[0]/rpm") );
		
		interpolate("/sim/models/engines/engine[0]/n1",0, getprop("/sim/models/engines/settings/time_shutdown") );
		interpolate("/sim/models/engines/engine[0]/n2",0, getprop("/sim/models/engines/settings/time_shutdown"));
		interpolate("/sim/models/engines/engine[0]/rpm",0, getprop("/sim/models/engines/settings/time_shutdown"));
		
		interpolate("/sim/models/engines/engine[1]/n1",0, getprop("/sim/models/engines/settings/time_shutdown"));
		interpolate("/sim/models/engines/engine[1]/n2",0, getprop("/sim/models/engines/settings/time_shutdown"));
		interpolate("/sim/models/engines/engine[1]/rpm",0, getprop("/sim/models/engines/settings/time_shutdown"));
		
	} else {
		print("SISTEMA : Virando motores... start!");
		setprop("/sim/models/engines/starting", 1);	

		interpolate("/sim/models/engines/engine[0]/fuel-consumed-lbs", getprop("/sim/models/engines/settings/idle-fuel-consumed-lbs"), getprop("/sim/models/engines/settings/time_start_n1") );
		interpolate("/sim/models/engines/engine[1]/fuel-consumed-lbs", getprop("/sim/models/engines/settings/idle-fuel-consumed-lbs"), getprop("/sim/models/engines/settings/time_start_n1") );
		
		interpolate("/sim/models/engines/engine[0]/n1", getprop("/sim/models/engines/settings/idle-n1"), getprop("/sim/models/engines/settings/time_start_n1") );
		interpolate("/sim/models/engines/engine[0]/n2", getprop("/sim/models/engines/settings/idle-n2"), getprop("/sim/models/engines/settings/time_start_n2") );
		interpolate("/sim/models/engines/engine[0]/rpm", getprop("/sim/models/engines/settings/idle-rpm"), getprop("/sim/models/engines/settings/time_start_rpm") );
		
		interpolate("/sim/models/engines/engine[1]/n1", getprop("/sim/models/engines/settings/idle-n1"), getprop("/sim/models/engines/settings/time_start_n1") );
		interpolate("/sim/models/engines/engine[1]/n2", getprop("/sim/models/engines/settings/idle-n2"), getprop("/sim/models/engines/settings/time_start_n2") );
		interpolate("/sim/models/engines/engine[1]/rpm", getprop("/sim/models/engines/settings/idle-rpm"), getprop("/sim/models/engines/settings/time_start_rpm") );
		
		settimer( func { 
			setprop("controls/engines/engine[0]/throttle", 0);
			setprop("controls/engines/engine[1]/throttle", 0);
			setprop("/sim/models/engines/starting" , 0); 
			print("SISTEMA : Start finalizado, rodando!");
			} , getprop("/sim/models/engines/settings/time_start") );
			
	}
},0,0);

var ctrlengines = func {
	var rodando = props.globals.getNode("/sim/model/start-idling", 1);
	var inicializando = props.globals.getNode("/sim/models/engines/starting", 1);
	
	if ( !rodando.getValue() or inicializando.getValue() ) {
		if ( inicializando.getValue() ) {
			var state = 1 ;
		} else {
			var state = 0 ;
		}
		
		setprop("engines/engine[0]/fuel-consumed-lbs", getprop("/sim/models/engines/engine[0]/fuel-consumed-lbs") );
		setprop("engines/engine[1]/fuel-consumed-lbs", getprop("/sim/models/engines/engine[1]/fuel-consumed-lbs") );
		
		setprop("engines/engine[0]/n1", getprop("/sim/models/engines/engine[0]/n1") );
		setprop("engines/engine[1]/n1", getprop("/sim/models/engines/engine[1]/n1") );
		
		setprop("engines/engine[0]/n2", getprop("/sim/models/engines/engine[0]/n2") );
		setprop("engines/engine[1]/n2", getprop("/sim/models/engines/engine[1]/n2") );

		setprop("engines/engine[0]/rpm", getprop("/sim/models/engines/engine[0]/rpm") );
		setprop("engines/engine[1]/rpm", getprop("/sim/models/engines/engine[1]/rpm") );
		
	} else { 
		
		var state = 1 ;
	}
		setprop("consumables/fuel/tank[0]/selected",state);
		setprop("consumables/fuel/tank[1]/selected",state);
		setprop("consumables/fuel/tank[2]/selected",state);
}


##############################################################
# System Objects Creation / Declaracao dos objetos do sistema
##############################################################

# Cria o propulsor 1
var L1eng = Engine.new(0);

# Cria o propulsor 2
var R2eng = Engine.new(1);

# Cria o limpador 
var wiper = Wiper.new("controls/electric/wipers","systems/electrical/bus-volts");


##########################################################
# System Update - Lopping / Agendando execucao do sistema
##########################################################
setlistener("/sim/signals/reinit", func {
    Shutdown();
});

setlistener("/sim/model/start-idling", func {
	var idle = props.globals.getNode("/sim/model/start-idling", 1);
    var run = idle.getBoolValue();
    if(run){
		Startup();
    }else{
		Shutdown();
    }
},0,0);

var update_systems = func {
	# Adicione aqui os motores criados
    L1eng.update();
    R2eng.update();
	
	ctrlengines();
	
	wiper.active();
    stall_horn();	
	
    settimer(update_systems,0);
}

setlistener("/sim/signals/fdm-initialized", func {
    settimer(update_systems,2);
});

