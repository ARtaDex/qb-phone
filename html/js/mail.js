var OpenedMail = null;

$(document).on('click', '.mail', function(e){
    e.preventDefault();

    $(".mail-home").animate({
        left: 30+"vh"
    }, 300);
    $(".opened-mail").animate({
        left: 0+"vh"
    }, 300);

    var MailData = $("#"+$(this).attr('id')).data('MailData');
    QB.Phone.Functions.SetupMail(MailData);

    OpenedMail = $(this).attr('id');
});

$(document).on('click', '.mail-back', function(e){
    e.preventDefault();

    $(".mail-home").animate({
        left: 0+"vh"
    }, 300);
    $(".opened-mail").animate({
        left: -30+"vh"
    }, 300);
    OpenedMail = null;
});

$(document).on('click', '#accept-mail', function(e){
    e.preventDefault();
    var MailData = $("#"+OpenedMail).data('MailData');
    $.post('https://phone/AcceptMailButton', JSON.stringify({
        buttonEvent: MailData.button.buttonEvent,
        buttonData: MailData.button.buttonData,
        mailId: MailData.mailid,
    }));
    $(".mail-home").animate({
        left: 0+"vh"
    }, 300);
    $(".opened-mail").animate({
        left: -30+"vh"
    }, 300);
});

$(document).on('click', '#remove-mail', function(e){
    e.preventDefault();
    var MailData = $("#"+OpenedMail).data('MailData');
    $.post('https://phone/RemoveMail', JSON.stringify({
        mailId: MailData.mailid
    }));
    $(".mail-home").animate({
        left: 0+"vh"
    }, 300);
    $(".opened-mail").animate({
        left: -30+"vh"
    }, 300);
});

QB.Phone.Functions.SetupMails = function(Mails) {
    var NewDate = new Date();
    var NewHour = NewDate.getHours();
    var NewMinute = NewDate.getMinutes();
    var Minutessss = NewMinute;
    var Hourssssss = NewHour;
    if (NewHour < 10) {
        Hourssssss = "0" + Hourssssss;
    }
    if (NewMinute < 10) {
        Minutessss = "0" + NewMinute;
    }
    var MessageTime = Hourssssss + ":" + Minutessss;

    var firstName = "User";
    var lastName = "Name";

    if (QB.Phone.Data.PlayerData && QB.Phone.Data.PlayerData.charinfo) {
        firstName = QB.Phone.Data.PlayerData.charinfo.firstname || "User";
        lastName = QB.Phone.Data.PlayerData.charinfo.lastname || "Name";
    }

    $("#mail-header-mail").html(firstName+"."+lastName+"@los-santos.com"); // Ganti domain sesuai keinginan
    $("#mail-header-lastsync").html("Last synchronized "+MessageTime);
    if (Mails !== null && Mails !== undefined) {
        if (Mails.length > 0) {
            $(".mail-list").html("");
            $.each(Mails, function(i, mail){
                var date = new Date(mail.date);
                var DateString = date.getDate()+" "+MonthFormatting[date.getMonth()]+" "+date.getFullYear()+" "+date.getHours()+":"+date.getMinutes();
                var element = '<div class="mail" id="mail-'+mail.mailid+'"><span class="mail-sender" style="font-weight: bold;">'+mail.sender+'</span> <div class="mail-text"><p>'+mail.message+'</p></div> <div class="mail-time">'+DateString+'</div></div>';

                $(".mail-list").append(element);
                $("#mail-"+mail.mailid).data('MailData', mail);
            });
        } else {
            $(".mail-list").html('<p class="nomails">You don\'t have any mails..</p>');
        }

    }
}

var MonthFormatting = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

QB.Phone.Functions.SetupMail = function(MailData) {
    var date = new Date(MailData.date);
    var DateString = date.getDate()+" "+MonthFormatting[date.getMonth()]+" "+date.getFullYear()+" "+date.getHours()+":"+date.getMinutes();
    $(".mail-subject").html("<p><span style='font-weight: bold;'>"+MailData.sender+"</span><br>"+MailData.subject+"</p>");
    $(".mail-date").html("<p>"+DateString+"</p>");
    $(".mail-content").html("<p>"+MailData.message+"</p>");

    var AcceptElem = '<div class="opened-mail-footer-item" id="accept-mail"><i class="fas fa-check-circle mail-icon"></i></div>';
    var RemoveElem = '<div class="opened-mail-footer-item" id="remove-mail"><i class="fas fa-trash-alt mail-icon"></i></div>';

    $(".opened-mail-footer").html("");

    if (MailData.button !== undefined && MailData.button !== null) {
        $(".opened-mail-footer").append(AcceptElem);
        $(".opened-mail-footer").append(RemoveElem);
        $(".opened-mail-footer-item").css({"width":"50%"});
    } else {
        $(".opened-mail-footer").append(RemoveElem);
        $(".opened-mail-footer-item").css({"width":"100%"});
    }
}

// Advert JS

$(document).on('click', '.test-slet', function(e){
    e.preventDefault();
    $(".advert-home").animate({
        left: 30+"vh"
    });
    $(".new-advert").animate({
        left: 0+"vh"
    });
});

$(document).on('click','.advimage', function (){
    let source = $(this).attr('src')
    QB.Screen.popUp(source);
});

$(document).on('click','#new-advert-photo',function(e){
    e.preventDefault();
    $.post('https://phone/TakePhoto',function(url){
        if(url){
            $('#advert-new-url').val(url)
        }
    })
    QB.Phone.Functions.Close();
});

$(document).on('click', '#new-advert-back', function(e){
    e.preventDefault();

    $(".advert-home").animate({
        left: 0+"vh"
    });
    $(".new-advert").animate({
        left: -30+"vh"
    });
});

$(document).on('click', '#new-advert-submit', function(e){
    e.preventDefault();
    var Advert = $(".new-advert-textarea").val();
    let picture = $('#advert-new-url').val();

    if (Advert !== "") {
        $(".advert-home").animate({
            left: 0+"vh"
        });
        $(".new-advert").animate({
            left: -30+"vh"
        });
        if (!picture){
            $.post('https://phone/PostAdvert', JSON.stringify({
                message: Advert,
                url: null
            }));
        }else {
            $.post('https://phone/PostAdvert', JSON.stringify({
                message: Advert,
                url: picture
            }));
        }
        $('#advert-new-url').val("")
        $(".new-advert-textarea").val("");
    } else {
        QB.Phone.Notifications.Add("fas fa-ad", "Advertisement", "You can\'t post an empty ad!", "#ff8f1a", 2000);
    }
});

QB.Phone.Functions.RefreshAdverts = function(Adverts) {
    // 1. Safe Check Data Player (Mencegah Error jika data belum siap)
    var firstName = "Guest";
    var lastName = "User";
    var phoneNumber = "00000";

    if (QB.Phone.Data.PlayerData && QB.Phone.Data.PlayerData.charinfo) {
        firstName = QB.Phone.Data.PlayerData.charinfo.firstname || "Guest";
        lastName = QB.Phone.Data.PlayerData.charinfo.lastname || "User";
        phoneNumber = QB.Phone.Data.PlayerData.charinfo.phone || "00000";
    }

    $("#advert-header-name").html("@" + firstName + " " + lastName + " | " + phoneNumber);

    // 2. Cek Jumlah Iklan (Support Array & Object)
    // Ini memperbaiki masalah list tidak muncul
    var advertCount = 0;
    if (Adverts) {
        if (Array.isArray(Adverts)) {
            advertCount = Adverts.length;
        } else {
            // Jika Object/Dictionary, hitung keys-nya
            advertCount = Object.keys(Adverts).length;
        }
    }

    if (advertCount > 0) {
        $(".advert-list").html("");
$.each(Adverts, function(i, advert){
    // Skip jika data kosong
    if (!advert) return;

    var clean = DOMPurify.sanitize(advert.message , {
        ALLOWED_TAGS: [],
        ALLOWED_ATTR: []
    });

    if (clean == '') { clean = 'I\'m a silly goose :/' }

    var element;
    
    // --- PERBAIKAN GAMBAR DI SINI ---
    if (advert.url && advert.url !== "") {
        // Perhatikan tanda kutip pada src="${advert.url}"
        element = `
        <div class="advert">
            <span class="advert-sender">${advert.name} | ${advert.number}</span>
            <p>${clean}</p>
            <br>
            <img class="advimage" src="${advert.url}" style="border-radius:4px; width: 95%; position:relative; z-index: 1; margin-bottom:1vh;" onclick="QB.Screen.popUp('${advert.url}')">
            <br>
            <span><div class="adv-icon"></div></span>
        </div>`;
    } else {
        element = `
        <div class="advert">
            <span class="advert-sender">${advert.name} | ${advert.number}</span>
            <p>${clean}</p>
        </div>`;
    }
    // -------------------------------

    $(".advert-list").append(element);

    // Logika tombol hapus (tetap sama)
    if (QB.Phone.Data.PlayerData.charinfo) {
        var myPhone = String(QB.Phone.Data.PlayerData.charinfo.phone);
        var advertPhone = String(advert.number);

        if (myPhone === advertPhone){
            $(".advert-list .advert:last").append('<i class="fas fa-trash" style="font-size: 1rem; position: absolute; right: 1vh; bottom: 1vh; cursor: pointer; color: white;" id="adv-delete"></i>');
        }
    }
});
    } else {
        $(".advert-list").html("");
        var element = '<div class="advert"><span class="advert-sender">There are no advertisements yet!</span></div>';
        $(".advert-list").append(element);
    }
}

$(document).on('click','#adv-delete',function(e){
    e.preventDefault();
    $.post('https://phone/DeleteAdvert', function(){
        setTimeout(function(){
            QB.Phone.Notifications.Add("fas fa-ad", "Advertisement", "The ad was deleted", "#ff8f1a", 2000);
        },400)
    });
})
