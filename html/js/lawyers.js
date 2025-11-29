SetupLawyers = function(data) {
    $(".lawyers-list").html("");

    // 1. Siapkan Wadah untuk setiap pekerjaan
    var services = {
        police: { label: "POLICE", color: "rgb(0, 102, 255)", list: [] },
        ambulance: { label: "AMBULANCE", color: "rgb(231, 76, 60)", list: [] },
        mechanic: { label: "MECHANIC", color: "rgb(230, 126, 34)", list: [] },
        taxi: { label: "TAXI", color: "rgb(241, 196, 15)", list: [] },
        lawyer: { label: "LAWYERS", color: "rgb(42, 137, 214)", list: [] },
        realestate: { label: "REAL ESTATE", color: "rgb(46, 204, 113)", list: [] },
        cardealer: { label: "CARD DEALER", color: "rgb(155, 89, 182)", list: [] }
    };

    // 2. Masukkan data pemain ke wadah yang sesuai
    if (data.length > 0) {
        $.each(data, function(i, person) {
            var jobName = person.job; 
            if (services[jobName]) {
                services[jobName].list.push(person);
            }
        });
    }

    // 3. Render Tampilan
    $.each(services, function(jobKey, serviceData) {
        // A. Buat Header Kategori
        var headerColor = serviceData.color;
        var headerHTML = `
            <div class="service-header" style="background-color: ${headerColor};">
                ${serviceData.label} (${serviceData.list.length})
            </div>`;
        $(".lawyers-list").append(headerHTML);

        // B. Buat List Pemain
        if (serviceData.list.length > 0) {
            $.each(serviceData.list, function(index, person) {
                // GANTI ICON PHONE JADI ICON CHAT
                var element = `
                <div class="lawyer-list" id="service-${jobKey}-${index}">
                    <div class="lawyer-list-firstletter" style="color: ${headerColor}; border: 1px solid ${headerColor};">
                        ${person.name.charAt(0).toUpperCase()}
                    </div>
                    <div class="lawyer-list-fullname">${person.name}</div>
                    <div class="lawyer-list-call" style="color: ${headerColor};">
                        <i class="fas fa-comment-dots"></i> 
                    </div>
                </div>`;
                
                $(".lawyers-list").append(element);
                
                // Simpan data
                $(`#service-${jobKey}-${index}`).data('ServiceData', person);
            });
        } else {
            // Pesan jika kosong
            $(".lawyers-list").append(`<div class="no-lawyers">No ${serviceData.label.toLowerCase()} available.</div>`);
        }
    });
}

// --- LOGIKA BARU: BUKA WHATSAPP SAAT DIKLIK ---
// ... (Kode SetupLawyers biarkan sama) ...

// --- LOGIKA BARU: FIX UI OVERLAPPING ---
$(document).on('click', '.lawyer-list-call', function(e){
    e.preventDefault();
    var ParentId = $(this).parent().attr('id');
    var ServiceData = $("#"+ParentId).data('ServiceData');
    
    // Cek apakah ini nomor sendiri
    if (ServiceData.phone !== QB.Phone.Data.PlayerData.charinfo.phone) {
        
        // 1. TUTUP PAKSA APP SERVICE (Hard Hide)
        // Kita gunakan .css langsung agar instan, jangan pakai animasi fadeOut agar tidak tumpuk
        $(".lawyers-app").css({"display":"none"}); 
        
        // 2. BUKA APP WHATSAPP
        $(".whatsapp-app").css({"display":"block"});
        QB.Phone.Data.currentApplication = "whatsapp";

        // 3. Load Data Chat
        $.post('https://phone/GetWhatsappChat', JSON.stringify({phone: ServiceData.phone}), function(chat){
            QB.Phone.Functions.SetupChatMessages(chat, {
                name: ServiceData.name,
                number: ServiceData.phone
            });
        });

        // 4. Load List Chat di Background
        $.post('https://phone/GetWhatsappChats', JSON.stringify({}), function(chats){
            QB.Phone.Functions.LoadWhatsappChats(chats);
        });

        // 5. Atur Posisi UI WhatsApp (Chat Room Muncul, Chat List Sembunyi)
        $('.whatsapp-openedchat-messages').animate({scrollTop: 9999}, 0); // Scroll ke bawah
        
        $(".whatsapp-openedchat").css({"display":"block", "left":"0vh"}); // Tampilkan Room Chat
        $(".whatsapp-chats").css({"display":"none", "left":"30vh"});     // Sembunyikan List Chat

    } else {
        QB.Phone.Notifications.Add("fas fa-comment-slash", "WhatsApp", "You can't chat with yourself!", "#e74c3c", 2500);
    }
});