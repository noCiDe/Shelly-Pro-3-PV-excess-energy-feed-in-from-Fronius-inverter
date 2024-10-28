// Shelly Pro Script in Shelly-Script zur Steuerung der Phasen basierend auf der Netzeinspeisung
// Phasen schalten bei: -1300 W, -2700 W und -4000 W (negative Werte für Netzeinspeisung)

let FRONIUS_API_URL = "http://192.168.168.222/solar_api/v1/GetPowerFlowRealtimeData.fcgi";

// Leistungsschwellenwerte (in Watt) für negative Netzeinspeisung
let PHASE1_THRESHOLD = -1300;
let PHASE2_THRESHOLD = -2700;
let PHASE3_THRESHOLD = -4000;

// Funktion zur Abfrage der Netzeinspeisung vom Fronius Wechselrichter
function getFroniusPower() {
  Shelly.call(
    "HTTP.GET", 
    { url: FRONIUS_API_URL },
    function (response) {
      if (response.code === 200) {
        let data = JSON.parse(response.body);
        let power = data.Body.Data.Site.P_Grid;  // "P_Grid" für aktuelle Netzeinspeisung
        controlShellyPhases(power);
      } else {
        print("Fehler beim Abrufen der Daten vom Fronius Wechselrichter");
      }
    }
  );
}

// Funktion zur Steuerung der Shelly Pro Phasen basierend auf Netzeinspeisung
function controlShellyPhases(power) {
  // Wenn die Einspeisung negativ ist (Strom wird ins Netz gespeist)
  if (power <= PHASE3_THRESHOLD) {
    // Schalte Phase 1, 2 und 3 ein, wenn Netzeinspeisung unter -4000 W
    Shelly.call("Switch.Set", { id: 0, on: true });  // Phase 1
    Shelly.call("Switch.Set", { id: 1, on: true });  // Phase 2
    Shelly.call("Switch.Set", { id: 2, on: true });  // Phase 3
  } else if (power <= PHASE2_THRESHOLD && power > PHASE3_THRESHOLD) {
    // Schalte Phase 1 und 2 ein, Phase 3 aus, wenn Netzeinspeisung zwischen -2700 W und -4000 W liegt
    Shelly.call("Switch.Set", { id: 0, on: true });  // Phase 1
    Shelly.call("Switch.Set", { id: 1, on: true });  // Phase 2
    Shelly.call("Switch.Set", { id: 2, on: false }); // Phase 3
  } else if (power <= PHASE1_THRESHOLD && power > PHASE2_THRESHOLD) {
    // Schalte nur Phase 1 ein, Phase 2 und 3 aus, wenn Netzeinspeisung zwischen -1300 W und -2700 W liegt
    Shelly.call("Switch.Set", { id: 0, on: true });  // Phase 1
    Shelly.call("Switch.Set", { id: 1, on: false }); // Phase 2
    Shelly.call("Switch.Set", { id: 2, on: false }); // Phase 3
  } else if (power > 0) {
    // Schalte alle Phasen aus, wenn Leistung aus dem Netz bezogen wird (positive Netzeinspeisung)
    Shelly.call("Switch.Set", { id: 0, on: false }); // Phase 1 aus
    Shelly.call("Switch.Set", { id: 1, on: false }); // Phase 2 aus
    Shelly.call("Switch.Set", { id: 2, on: false }); // Phase 3 aus
  }
}

// Abfrage der Netzeinspeisung alle 60 Sekunden
Timer.set(60000, true, function() {
  getFroniusPower();
});