(async function () {
  let data;
  try {
    const response = await fetch('data.json');
    if (!response.ok) throw new Error(response.statusText);
    data = await response.json();
  } catch {
    document.body.innerHTML = '<h1>No benchmark data available yet.</h1>';
    return;
  }

  if (!data || !data.entries) {
    document.body.innerHTML = '<h1>No benchmark data available yet.</h1>';
    return;
  }

  const qualityEntries = data.entries['Skills Evaluation - Quality'] || [];
  const efficiencyEntries = data.entries['Skills Evaluation - Efficiency'] || [];

  // Extract scenario names from the latest quality entry
  const latestQuality = qualityEntries[qualityEntries.length - 1];
  const scenarios = new Set();
  if (latestQuality) {
    latestQuality.benches.forEach(b => {
      const match = b.name.match(/^(.+) - (Skilled|Vanilla) Quality$/);
      if (match) scenarios.add(match[1]);
    });
  }

  // Build summary cards from latest data
  const summaryDiv = document.getElementById('summary-cards');
  if (latestQuality) {
    const skilledAvg = latestQuality.benches.find(b => b.name === 'Overall - Skilled Avg Quality');
    const vanillaAvg = latestQuality.benches.find(b => b.name === 'Overall - Vanilla Avg Quality');
    if (skilledAvg && vanillaAvg) {
      const delta = (skilledAvg.value - vanillaAvg.value).toFixed(2);
      const deltaClass = delta > 0 ? 'positive' : delta < 0 ? 'negative' : 'neutral';
      const deltaSign = delta > 0 ? '+' : '';
      summaryDiv.innerHTML = `
        <div class="card">
          <div class="card-label">Skilled Avg</div>
          <div class="card-value" style="color: var(--skilled)">${skilledAvg.value.toFixed(2)}</div>
          <div class="card-delta">out of 10.0</div>
        </div>
        <div class="card">
          <div class="card-label">Vanilla Avg</div>
          <div class="card-value" style="color: var(--vanilla)">${vanillaAvg.value.toFixed(2)}</div>
          <div class="card-delta">out of 10.0</div>
        </div>
        <div class="card">
          <div class="card-label">Delta</div>
          <div class="card-value ${deltaClass}">${deltaSign}${delta}</div>
          <div class="card-delta ${deltaClass}">${delta > 0 ? 'Skills improve quality' : delta < 0 ? 'Skills degrade quality' : 'No difference'}</div>
        </div>
        <div class="card">
          <div class="card-label">Data Points</div>
          <div class="card-value">${qualityEntries.length}</div>
          <div class="card-delta">evaluation runs</div>
        </div>
        <div class="card">
          <div class="card-label">Model</div>
          <div class="card-value" style="font-size: 18px">${latestQuality.model || 'N/A'}</div>
          <div class="card-delta">latest run</div>
        </div>
      `;
    }
  }

  // Helper: create a paired line chart
  function createPairedChart(container, title, entries, nameA, nameB, labelA, labelB, colorA, colorB) {
    const div = document.createElement('div');
    div.className = 'chart-container';
    div.innerHTML = `<h3>${title}</h3><canvas></canvas>`;
    container.appendChild(div);
    const canvas = div.querySelector('canvas');

    const labels = entries.map(e => {
      const d = new Date(e.date);
      return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    });

    const dataA = entries.map(e => {
      const b = e.benches.find(b => b.name === nameA);
      return b ? b.value : null;
    });

    const dataB = entries.map(e => {
      const b = e.benches.find(b => b.name === nameB);
      return b ? b.value : null;
    });

    new Chart(canvas, {
      type: 'line',
      data: {
        labels,
        datasets: [
          {
            label: labelA,
            data: dataA,
            borderColor: colorA,
            backgroundColor: colorA + '20',
            borderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 6,
            tension: 0.3,
            fill: false
          },
          {
            label: labelB,
            data: dataB,
            borderColor: colorB,
            backgroundColor: colorB + '20',
            borderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 6,
            tension: 0.3,
            borderDash: [5, 5],
            fill: false
          }
        ]
      },
      options: {
        responsive: true,
        interaction: { mode: 'index', intersect: false },
        plugins: {
          legend: { labels: { color: '#8b949e', font: { size: 11 } } },
          tooltip: {
            callbacks: {
              afterTitle: (items) => {
                const idx = items[0].dataIndex;
                const entry = entries[idx];
                const parts = [];
                if (entry && entry.model) parts.push(`Model: ${entry.model}`);
                if (entry && entry.commit) {
                  const msg = entry.commit.message.split('\n')[0];
                  parts.push(msg.length > 60 ? msg.substring(0, 60) + '...' : msg);
                }
                return parts.join('\n');
              }
            }
          }
        },
        scales: {
          x: { ticks: { color: '#8b949e' }, grid: { color: '#30363d' } },
          y: {
            ticks: { color: '#8b949e' },
            grid: { color: '#30363d' },
            suggestedMin: title.includes('Quality') ? 0 : undefined,
            suggestedMax: title.includes('Quality') ? 10 : undefined
          }
        }
      }
    });
  }

  // Render quality charts (paired: Skilled vs Vanilla)
  const qualityChartsDiv = document.getElementById('quality-charts');

  // Overall chart first
  createPairedChart(
    qualityChartsDiv, 'Overall Average Quality', qualityEntries,
    'Overall - Skilled Avg Quality', 'Overall - Vanilla Avg Quality',
    'Skilled', 'Vanilla', '#58a6ff', '#8b949e'
  );

  // Per-scenario quality charts
  scenarios.forEach(scenario => {
    createPairedChart(
      qualityChartsDiv, scenario, qualityEntries,
      `${scenario} - Skilled Quality`, `${scenario} - Vanilla Quality`,
      'Skilled', 'Vanilla', '#58a6ff', '#8b949e'
    );
  });

  // Render efficiency charts (single series per scenario)
  const efficiencyChartsDiv = document.getElementById('efficiency-charts');
  if (efficiencyEntries.length > 0) {
    const latestEff = efficiencyEntries[efficiencyEntries.length - 1];
    const effScenarios = new Set();
    latestEff.benches.forEach(b => {
      const match = b.name.match(/^(.+) - Skilled Time$/);
      if (match) effScenarios.add(match[1]);
    });

    effScenarios.forEach(scenario => {
      const div = document.createElement('div');
      div.className = 'chart-container';
      div.innerHTML = `<h3>${scenario}</h3><canvas></canvas>`;
      efficiencyChartsDiv.appendChild(div);
      const canvas = div.querySelector('canvas');

      const labels = efficiencyEntries.map(e => {
        const d = new Date(e.date);
        return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      });

      const timeData = efficiencyEntries.map(e => {
        const b = e.benches.find(b => b.name === `${scenario} - Skilled Time`);
        return b ? b.value : null;
      });

      const tokenData = efficiencyEntries.map(e => {
        const b = e.benches.find(b => b.name === `${scenario} - Skilled Tokens In`);
        return b ? b.value / 1000 : null;
      });

      new Chart(canvas, {
        type: 'line',
        data: {
          labels,
          datasets: [
            {
              label: 'Time (s)',
              data: timeData,
              borderColor: '#f0883e',
              borderWidth: 2,
              pointRadius: 4,
              tension: 0.3,
              fill: false,
              yAxisID: 'y'
            },
            {
              label: 'Tokens In (k)',
              data: tokenData,
              borderColor: '#a371f7',
              borderWidth: 2,
              pointRadius: 4,
              tension: 0.3,
              borderDash: [5, 5],
              fill: false,
              yAxisID: 'y1'
            }
          ]
        },
        options: {
          responsive: true,
          interaction: { mode: 'index', intersect: false },
          plugins: { legend: { labels: { color: '#8b949e', font: { size: 11 } } } },
          scales: {
            x: { ticks: { color: '#8b949e' }, grid: { color: '#30363d' } },
            y: {
              type: 'linear',
              position: 'left',
              ticks: { color: '#f0883e' },
              grid: { color: '#30363d' },
              title: { display: true, text: 'seconds', color: '#f0883e' }
            },
            y1: {
              type: 'linear',
              position: 'right',
              ticks: { color: '#a371f7' },
              grid: { drawOnChartArea: false },
              title: { display: true, text: 'tokens (k)', color: '#a371f7' }
            }
          }
        }
      });
    });
  }
})();
