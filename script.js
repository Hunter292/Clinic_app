document.addEventListener("DOMContentLoaded", function () {
    var menu = document.getElementById("menu");
    var menuBuff = document.getElementById("menu-buff");
    var menuY = menu.offsetTop;

    function stickymenu() {
        var scrollY = window.scrollY;
        if (scrollY > menuY) {
            menu.classList.add("sticky");
            menuBuff.classList.add("menu-buff-a");
        } else {
            menu.classList.remove("sticky");
            menuBuff.classList.remove("menu-buff-a");
        }
    }

    stickymenu();
    window.addEventListener("scroll", stickymenu);
});