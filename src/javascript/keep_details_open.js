document.querySelectorAll('details').forEach(details => {
  details.addEventListener('toggle', (e) => {
    sessionStorage.setItem(`details#${details.id}`, e.target.open);
  });

  const isOpen = sessionStorage.getItem(`details#${details.id}`);
  if (isOpen === 'true') {
    details.open = true;
  }
});
