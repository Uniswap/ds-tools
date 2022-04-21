import streamlit as st
import pandas as pd
import numpy as np
import sys
import matplotlib
sys.path.append('/Users/wanxin/Documents/GitHub/ds-tools')
import dbtools as dbt
from google.cloud import bigquery
import seaborn as sns
import matplotlib.pyplot as plt

# set page title
st.title('Market Depth Dashboard')

# Create a text element and let the reader know the data is loading.
data_load_state = st.text('Loading data...')

# load data from BigQuery
data_query = f'''
SELECT 
    date,
    token1,
    depth0
     FROM `mimetic-design-338620.uniswap.depth_daily` 
where date > '2022-01-01'
and pct = -0.02
and token0 = 'USDC'
and token1 is not null 
and token1 != 'USDT'
'''

# @st.cache
def load_from_bigquery(query):
    return dbt.bigquery(query)

market_depth_data = load_from_bigquery(data_query)

# Notify the reader that the data was successfully loaded.
data_load_state.text('Loading data...done! (cache used when possible)')

# Inspect Raw data
st.subheader('Raw data')
st.write(market_depth_data)

# Create a text element and let the reader know the plot is drawing.
plot_drawing_state = st.text('Drawing plot...')

# Draw a plot
st.set_option('deprecation.showPyplotGlobalUse', False)
ax = sns.lineplot(data = market_depth_data, x='date', y='depth0', hue='token1', ci=None)
ax.set_ylabel('-2% market depth ($)')
plt.legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.)
st.pyplot()

# Notify the reader that the plot was successfully drawn.
plot_drawing_state.text('Drawing plot...done!')
