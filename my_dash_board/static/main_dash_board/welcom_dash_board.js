

document.addEventListener("DOMContentLoaded", async function () {
  const hero_quote = document.querySelector(".hero-quote");
  const day_count = document.querySelector(".hero-title")
  try {
    const response = await fetch('/my_dashboard/api1/getTodayQuote');
    if (response.ok) {
      // showToast(`Successfully deleted ${selectedValues.length} UTP pack(s)`, 'success');
      const body = await response.json();
      hero_quote.innerHTML = body.message;
      day_count.innerHTML = `Day : ${body.dailyCount}`
    }
  } catch (err) {
    console.log(err);
    hero_quote.innerHTML = "MISTER LEADER OF THE FREE GALAXY"
  }
});
