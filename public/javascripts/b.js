subs = sessionStorage.getItem("subscriptions");
prefs = sessionStorage.getItem("preferences");

document.addEventListener("DOMContentLoaded", function() {
  const subsList = document.getElementById("subs");
  subsArr = subs.split(",");
  subsFormatted = "";
  subsArr.forEach(sub => {
    if (sub === subsArr.slice(-1)[0]) {
      subsFormatted += sub;
    } else {
      subsFormatted += sub + ", ";
    }
  });
  subsList.innerText = subsFormatted;

  const prefsObj = JSON.parse(prefs);
  const prefsTbody = document.getElementById("tbody");
  Object.keys(prefsObj).forEach(pref => {
    const tr = document.createElement("tr");
    const setting = document.createElement("td");
    const value = document.createElement("td");
    setting.innerText = pref;
    value.innerText = prefsObj[pref];
    tr.appendChild(setting);
    tr.appendChild(value);
    prefsTbody.appendChild(tr);
  });

  const subBtn = document.getElementById("sub-btn");
  const prefsBtn = document.getElementById("prefs-btn");
  const subResult = document.getElementById("sub-result");
  const prefsResult = document.getElementById("prefs-result");

  subBtn.addEventListener("click", async _ => {
    try {
      const response = await fetch(
        "/2",
        {
          method: "post",
          body: JSON.stringify({ subscriptions: subs })
        });
      if (response.status > 200) {
        throw response.statusText;
      }
      subResult.innerText = "Success! Subscriptions added to your new account.";
    } catch(err) {
      subResult.innerText = `Error: ${err}`;
    }
  });

  prefsBtn.addEventListener("click", async _ => {
    try {
      const response = await fetch(
        "/2",
        {
          method: "post",
          body: JSON.stringify({ preferences: prefs })
        });
      if (response.status > 200) {
        throw response.statusText;
      }
      prefsResult.innerText = "Success! Preferences migrated to your new account.";
    } catch(err) {
      prefsResult.innerText = `Error: ${err}`;
    }
  });
});
