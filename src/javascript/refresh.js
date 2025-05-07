let timeout = Number((new URLSearchParams(window.location.search)).get("refresh"));
if (timeout) setTimeout(location.reload.bind(location), timeout * 1000);
