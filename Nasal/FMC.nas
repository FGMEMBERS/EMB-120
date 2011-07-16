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

# Create initial announced variables at startup of the sim
V1 = "106";
VR = "112";
V2 = "124";
PR = "100";

var FMC_flaps = props.globals.initNode("/instrumentation/fmc/to-flap",15,"INT");
var WTn = props.globals.initNode("/yasim/gross-weight-lbs",0,"DOUBLE");
var FMC_v80 = props.globals.initNode("/instrumentation/fmc/vspeeds/V80",80,"DOUBLE");
var FMC_RateRef = props.globals.initNode("/instrumentation/fmc/settings/RR",400,"DOUBLE");

# The actual function
var vspeeds = func {

       # Create/populate variables at each function cycle
       # Retrieve total aircraft weight and convert to kg.
	var WT = getprop("/yasim/gross-weight-lbs") ;
	flaps = getprop("/instrumentation/fmc/to-flap");
	
	var OAT = getprop("/environment/temperature-degc") ;
	
       # Calculate V-speeds with flaps 15
	if (flaps == 15) {
		V1 = 72.26604 + ( 0.00241 * OAT) + ( 0.00150 * WT) ;
		VR = 84.39016 - ( 0.03769 * OAT) + ( 0.00113 * WT) ;
		V2 = 122.09423 - ( 0.13403 * OAT) - ( 0.00020789 * WT) ;
	}

       # Calculate V-speeds with flaps 25
	elsif (flaps == 25) {
		V1 = 72.26604 + ( 0.00241 * OAT) + ( 0.00150 * WT) ;
		VR = 84.39016 - ( 0.03769 * OAT) + ( 0.00113 * WT) ;
		V2 = 122.09423 - ( 0.13403 * OAT) - ( 0.00020789 * WT) ;
	}

       # Export the calculated V-speeds to the property-tree, for further use
	setprop("/instrumentation/fmc/vspeeds/V1",V1);
	setprop("/instrumentation/fmc/vspeeds/VR",VR);
	setprop("/instrumentation/fmc/vspeeds/V2",V2);

       # Repeat the function each second
	settimer(vspeeds, 1);
}

# Only start the function when the FDM is initialized, to prevent the problem of not-yet-created properties.
_setlistener("/sim/signals/fdm-initialized", vspeeds);


setlistener("/sim/signals/fdm-initialized", func {
   copilot.init()
});

# Copilot announcements
var copilot = {
   init : func { 
       me.UPDATE_INTERVAL = 1.73; 
       me.loopid = 0;
       # Initialize state variables.
       me.V80announced = 0;
       me.V1announced = 0;
       me.VRannounced = 0;
       me.V2announced = 0;
       me.PRannounced = 0;
       me.reset(); 
       print("Copilot ready"); 
   }, 
   update : func {
       var airspeed = getprop("velocities/airspeed-kt");
       var V80 = getprop("instrumentation/fmc/vspeeds/V80");
       var V1 = getprop("instrumentation/fmc/vspeeds/V1");
       var V2 = getprop("instrumentation/fmc/vspeeds/V2");
       var VR = getprop("instrumentation/fmc/vspeeds/VR");
       var PRate = getprop("instrumentation/vertical-speed-indicator/indicated-speed-fpm");
       var RateRef = getprop("instrumentation/fmc/settings/RR");
       var TimeEL = getprop("/sim/time/elapsed-sec");
       var MinTime = 60 ;
       
       #Check if the V1, VR and V2 callouts should occur and if so, add to the announce function
       if ((airspeed != nil) and (V80 != nil) and (airspeed > 80.0) and (me.V80announced == 0)) {
           me.announce("80 kts!");
               me.V80announced = 1;

       } elsif ((airspeed != nil) and (V1 != nil) and (airspeed > V1) and (me.V1announced == 0)) {
           me.announce("V1!");
               me.V1announced = 1;

       } elsif ((airspeed != nil) and (VR != nil) and (airspeed > VR) and (me.VRannounced == 0)) {
           me.announce("VR!");
               me.VRannounced = 1;
               
       } elsif ((airspeed != nil) and (PRate != nil) and (RateRef != nil) and (PRate > RateRef) and (TimeEL > MinTime) and (me.PRannounced == 0)) {
           me.announce("Positive rate!");
               me.PRannounced = 1;

       } elsif ((airspeed != nil) and (V2 != nil) and (airspeed > V2) and (me.V2announced == 0)) {
           me.announce("V2!");
               me.V2announced = 1;
               
       } 

   },

   # Print the announcement on the screen
   announce : func(msg) {
       setprop("/sim/messages/copilot", msg);
   },
   reset : func {
       me.loopid += 1;
       me._loop_(me.loopid);
   },
   _loop_ : func(id) {
       id == me.loopid or return;
       me.update();
       settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
   }
};
