import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import cm
import seaborn as sns
import numpy as np

class Interval(pd._libs.interval.Interval):
    def __init__(self, interv):
        super(Interval, self).__init__(interv.left, interv.right, closed=interv.closed)
        assert self.closed_left, f'left: {self.closed_left}; right: {self.closed_right}'
    def __str__(self):
        assert f'left: {self.closed_left}; right: {self.closed_right}'
        if self.length == 1:
            return f'{self.left:.0f}'
        if np.isinf(self.right):
            return f'{self.left:.0f}+'
        return f'{self.left:.0f}–{self.right - 1:.0f}'

def counts_fig():
    from make_stats import Stats
    counts = Stats().counts
    bins = [1, 11, 21, 31, 41, 51, 61, 71, 81, 91,
              101, 201, 301, 401, 501, 601, 701, 801, 901,
              1001, np.inf]
    counts_bins = pd.DataFrame({'nr_compounds': counts, 'bins':
                                pd.cut(counts, bins=bins, right=False)})
    counts_bins['bins_str'] = [Interval(i) for i in counts_bins.bins]
    grouped = counts_bins.groupby('bins_str').count().reindex(counts_bins.bins.cat.categories).fillna(0).reset_index()
    grouped['index'] = [str(Interval(i)) for i in grouped['index']]

    fig, axes = plt.subplots(figsize=(9.34, 3.5), ncols=2)
    plt.rcParams['svg.fonttype'] = 'none'
    sns.barplot(data=grouped.iloc[:10], x='index', y='nr_compounds', color=cm.tab10.colors[0], ax=axes[0])
    axes[0].set(xlabel='Number of compounds per dataset',
           ylabel='Number of datasets')
    axes[0].tick_params(axis='x', labelrotation=45)
    axes[0].set_ylim(bottom=0)
    sns.barplot(data=grouped.iloc[10:], x='index', y='nr_compounds', color=cm.tab10.colors[0], ax=axes[1])
    axes[1].set(xlabel='Number of compounds per dataset',
           ylabel='Number of datasets')
    axes[1].tick_params(axis='x', labelrotation=45)
    axes[1].set_ylim(bottom=1)
    plt.tight_layout()
    plt.savefig('stats/counts.png', dpi=400)

if __name__ == '__main__':
    counts_fig()
