// update all img src's to include &dark=1
var darkmode = (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) || false;
if (darkmode) {
  document.querySelectorAll("img").forEach(img => {
    console.log(img)
    let src = img.getAttribute("src");
    img.setAttribute("src", src + "&dark=1");
  });
}
