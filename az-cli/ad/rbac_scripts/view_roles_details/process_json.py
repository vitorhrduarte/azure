import sys
import pandas as pd
import json
import os

# Load the JSON data
with open(sys.argv[1]) as file:
    data = json.load(file)

permissions_data = data.pop('permissions')

# Normalize the main data
df_main = pd.json_normalize(data)

# Create a DataFrame for permissions data and explode 'actions'
df_actions = pd.json_normalize(permissions_data).explode('actions')
df_actions['Key'] = 'actions'

# Create DataFrames for 'dataActions', 'notActions', and 'notDataActions' and explode them
df_dataActions = pd.json_normalize(permissions_data).explode('dataActions')
df_dataActions['Key'] = 'dataActions'

df_notActions = pd.json_normalize(permissions_data).explode('notActions')
df_notActions['Key'] = 'notActions'

df_notDataActions = pd.json_normalize(permissions_data).explode('notDataActions')
df_notDataActions['Key'] = 'notDataActions'

# Repeat df_main for the length of each exploded DataFrame
final_df_actions = pd.concat([df_main]*len(df_actions)).reset_index(drop=True)
final_df_dataActions = pd.concat([df_main]*len(df_dataActions)).reset_index(drop=True)
final_df_notActions = pd.concat([df_main]*len(df_notActions)).reset_index(drop=True)
final_df_notDataActions = pd.concat([df_main]*len(df_notDataActions)).reset_index(drop=True)

# Concatenate the df_main and DataFrames of 'actions', 'dataActions', 'notActions', and 'notDataActions'
final_df_actions = pd.concat([final_df_actions.reset_index(drop=True), df_actions.reset_index(drop=True)], axis=1)
final_df_dataActions = pd.concat([final_df_dataActions.reset_index(drop=True), df_dataActions.reset_index(drop=True)], axis=1)
final_df_notActions = pd.concat([final_df_notActions.reset_index(drop=True), df_notActions.reset_index(drop=True)], axis=1)
final_df_notDataActions = pd.concat([final_df_notDataActions.reset_index(drop=True), df_notDataActions.reset_index(drop=True)], axis=1)

# Combine all the final DataFrames
final_df = pd.concat([final_df_actions, final_df_dataActions, final_df_notActions, final_df_notDataActions])

# Write to CSV
filename = 'output.csv'
if os.path.exists(filename) and os.path.getsize(filename) > 0:
    final_df.to_csv(filename, mode='a', index=False, header=False)
else:
    final_df.to_csv(filename, mode='w', index=False)

