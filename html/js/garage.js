let veh;

$(document).on('click', '.garage-vehicle', function(e){
    e.preventDefault();

    $(".garage-homescreen").animate({
        left: 30+"vh"
    }, 200);
    $(".garage-detailscreen").animate({
        left: 0+"vh"
    }, 200);

    var Id = $(this).attr('id');
    var VehData = $("#"+Id).data('VehicleData');
    veh = VehData;
    SetupDetails(VehData);
});

$(document).on('click', '#track-vehicle', function(e){
    e.preventDefault();
    $.post("https://phone/track-vehicle", JSON.stringify({
        veh: veh,
    }));
});

$(document).on('click', '#return-button', function(e){
    e.preventDefault();

    $(".garage-homescreen").animate({
        left: 0+"vh"
    }, 200);
    $(".garage-detailscreen").animate({
        left: -30+"vh"
    }, 200);
});

SetupGarageVehicles = function(Vehicles) {
    $(".garage-vehicles").html("");
    if (Vehicles != null) {
        $.each(Vehicles, function(i, vehicle){
            // Gunakan fullname yang sudah diperbaiki di Client Lua
            var fullName = vehicle.fullname ? vehicle.fullname : "Unknown Vehicle";
            var firstLetter = fullName.charAt(0);

            // Tampilan di list
            var Element = '<div class="garage-vehicle" id="vehicle-'+i+'"><span class="garage-vehicle-firstletter">'+firstLetter+'</span> <span class="garage-vehicle-name">'+fullName+'</span> </div>';

            $(".garage-vehicles").append(Element);
            $("#vehicle-"+i).data('VehicleData', vehicle);
        });
    }
}

SetupDetails = function(data) {
    // --- FIX START: Safe Checks untuk Data Detail ---
    var brand = data.brand || "System";
    var model = data.model || data.label || "Vehicle";
    var plate = data.plate || "Unknown";
    var garage = data.garage || "Public Garage"; // Default jika data garasi tidak ada
    
    // Logika Status (Stored/Out)
    var status = "Out";
    if (data.state === 1 || data.stored === 1 || data.status === "stored" || data.status === true) {
        status = "Stored";
    }

    // Fallback Data Mesin (Agar tidak NaN jika server tidak mengirim data)
    var fuelLevel = (data.fuel !== undefined) ? data.fuel : 100;
    var engineHealth = (data.engine !== undefined) ? data.engine : 1000;
    var bodyHealth = (data.body !== undefined) ? data.body : 1000;
    // --- FIX END ---

    $(".vehicle-brand").find(".vehicle-answer").html(brand);
    $(".vehicle-model").find(".vehicle-answer").html(model);
    $(".vehicle-plate").find(".vehicle-answer").html(plate);
    $(".vehicle-garage").find(".vehicle-answer").html(garage);
    $(".vehicle-status").find(".vehicle-answer").html(status);
    
    // Math.ceil aman dilakukan karena variabel sudah dipastikan angka di atas
    $(".vehicle-fuel").find(".vehicle-answer").html(Math.ceil(fuelLevel) + "%");
    $(".vehicle-engine").find(".vehicle-answer").html(Math.ceil(engineHealth / 10) + "%");
    $(".vehicle-body").find(".vehicle-answer").html(Math.ceil(bodyHealth / 10) + "%");
}