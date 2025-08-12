import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.lines import Line2D
from matplotlib.patches import Circle
import os

COLORS = ['r', 'g', 'b', 'c', 'm', 'y']

# figsize=(7, 4) per trial
def plot_discrete_graph(trials, data, start, end, title, x_label, y_label, png_name, ttl_pulse_list=None):
    plt.rcParams.update({'font.size': 20})
    fig, graph = plt.subplots(figsize=(7 * len(trials), 4))

    for trial_index in trials:
        data_x = data[data['Trial'] == trial_index]['AbsCodeTime'].to_list()
        data_y = [1] * len(data_x)
        graph.stem(data_x, data_y, linefmt=COLORS[trial_index] + '-', markerfmt='o', basefmt=" ",
                   label='Trial {}'.format(trial_index))

    if ttl_pulse_list is not None:
        graph.stem(ttl_pulse_list, [1] * len(ttl_pulse_list), linefmt='k-', markerfmt='o', basefmt=" ",
                   label='TTL between\ntrials')

    graph.set_ylim(0, 1.2)
    graph.set_xlim(start - 1000, end + 1000)
    graph.set_title(title)
    graph.set_xlabel(x_label)
    graph.set_ylabel(y_label)
    graph.legend(bbox_to_anchor=(0.95, 1.15), loc='upper left')
    graph.grid(False)
    fig.savefig(png_name, dpi=100)
    plt.close()


def plot_trial_start_end_graph(trials, data, title, x_label, y_label, png_name):
    plt.rcParams.update({'font.size': 20})
    fig, graph = plt.subplots(figsize=(7 * len(trials), 4))

    first_trial = trials[0]
    for trial_index in trials:
        data_x = data[trial_index - first_trial]
        data_y = [1] * len(data_x)
        graph.stem(data_x, data_y, linefmt=COLORS[trial_index] + '-', markerfmt='o', basefmt=" ",
                   label='Trial {}'.format(trial_index))

    graph.set_ylim(0, 1.2)
    graph.set_xlim(data[0][0] - 1000, data[-1][1] + 1000)
    graph.set_title(title)
    graph.set_xlabel(x_label)
    graph.set_ylabel(y_label)
    graph.legend(bbox_to_anchor=(0.95, 1.15), loc='upper left')
    graph.grid(False)
    fig.savefig(png_name, dpi=100)
    plt.close()


def plot_continuous_graph(trials, data, start_time, end_time, title, x_label, y_label, png_name):
    plt.rcParams.update({'font.size': 20})
    fig, graph = plt.subplots(figsize=(7 * len(trials), 4))

    first_trial = trials[0]
    for trial_index in trials:
        x = np.linspace(start_time[trial_index - first_trial], end_time[trial_index - first_trial] + 100, 2000)
        y = np.where((x >= data['start'][trial_index - first_trial]) & (x <= data['end'][trial_index - first_trial]), 1,
                     0)
        graph.plot(x, y, label='Signal {}'.format(trial_index), color=COLORS[trial_index])

    graph.set_ylim(-0.2, 1.2)
    graph.set_xlim(start_time[0] - 1000, end_time[-1] + 1000)
    graph.set_title(title)
    graph.set_xlabel(x_label)
    graph.set_ylabel(y_label)
    graph.legend(bbox_to_anchor=(0.95, 1.15), loc='upper left')
    graph.grid(False)
    fig.savefig(png_name, dpi=100)
    plt.close()


def plot_everything_in_one_graph(trials, trial_start_data, trial_end_data, baseline_data, stimulus_data,
                                 reward_data, punish_data, ttl_data, ttl_pulse_data, eye_pos_data, total_offline_time,
                                 title, png_name):
    plt.rcParams.update({'font.size': 20})
    # fig, graph = plt.subplots(figsize=(20 * len(trials), 4))
    fig, graph = plt.subplots(figsize=(50 * len(trials), 8))

    if ttl_pulse_data is not None:
        graph.stem(ttl_pulse_data, [0.1] * len(ttl_pulse_data), linefmt='b-', markerfmt='o', basefmt=" ")

    first_trial = trials[0]
    for trial_index in trials:
        trial_start_data_x = trial_start_data[trial_index - first_trial]
        markerline, stemlines, baseline = graph.stem([trial_start_data_x], [1], linefmt='k-', markerfmt='o',
                                                     basefmt=" ", label='Trial Start')
        plt.setp(stemlines, 'linewidth', 3)

        trial_end_data_x = trial_end_data[trial_index - first_trial]
        markerline, stemlines, baseline = graph.stem([trial_end_data_x], [1], linefmt='k--', markerfmt='o', basefmt=" ",
                                                     label='Trial End')
        plt.setp(stemlines, 'linewidth', 4.5)

        ttl_x = ttl_data[ttl_data['Trial'] == trial_index]['AbsCodeTime'].to_list()
        ttl_y = [0.1] * len(ttl_x)
        graph.stem(ttl_x, ttl_y, linefmt='b-', markerfmt='o', basefmt=" ", label='TTL')

        reward_x = reward_data[reward_data['Trial'] == trial_index]['AbsCodeTime'].to_list()
        if len(reward_x) != 0:
            reward_y = [1] * len(reward_x)
            graph.stem(reward_x, reward_y, linefmt='g-', markerfmt='o', basefmt=" ", label='Reward')

        punish_x = punish_data[punish_data['Trial'] == trial_index]['AbsCodeTime'].to_list()
        if len(punish_x) != 0:
            punish_y = [1] * len(punish_x)
            graph.stem(punish_x, punish_y, linefmt='r-', markerfmt='o', basefmt=" ", label='No Reward')

        eye_pos_magnitude = eye_pos_data.iloc[0:int(eye_pos_data.loc[eye_pos_data['eye_pos{:02d}_magnitude'.format(trial_index)].last_valid_index()]['timestamp']) + 1][['timestamp', 'eye_pos{:02d}_magnitude'.format(trial_index)]]
        eye_pos_magnitude.loc[eye_pos_magnitude['eye_pos{:02d}_magnitude'.format(trial_index)] > 3.5, 'eye_pos{:02d}_magnitude'.format(trial_index)] = 3.5
        eye_pos_magnitude['eye_pos{:02d}_magnitude'.format(trial_index)] = eye_pos_magnitude['eye_pos{:02d}_magnitude'.format(trial_index)] + 1.5
        eye_pos_magnitude['timestamp'] = eye_pos_magnitude['timestamp'] + total_offline_time
        eye_pos_magnitude = eye_pos_magnitude[eye_pos_magnitude['timestamp'] >= trial_start_data_x]

        graph.scatter(eye_pos_magnitude['timestamp'].to_list(),
                      eye_pos_magnitude['eye_pos{:02d}_magnitude'.format(trial_index)].to_list(),
                      marker='o', color='purple', s=2, label='Eye Position')
        graph.axhline(y=1.5, color='red', linestyle='--', label='Fixation at 1.5')

        continuous_graph_x = np.linspace(trial_start_data_x, trial_end_data_x + 1, 3000)
        baseline_data_y = np.where((continuous_graph_x >= baseline_data['start'][trial_index - first_trial]) &
                                   (continuous_graph_x <= baseline_data['end'][trial_index - first_trial]), 0.4, 0)
        graph.plot(continuous_graph_x, baseline_data_y, label='Baseline', color='gray', linewidth=3)

        stimulus_data_y = np.where((continuous_graph_x >= stimulus_data['start'][trial_index - first_trial]) &
                                   (continuous_graph_x <= stimulus_data['end'][trial_index - first_trial]), 0.8, 0.02)
        graph.plot(continuous_graph_x, stimulus_data_y, label='Stimulus', color='orange', linewidth=3)

    graph.set_ylim(0, 5.2)
    custom_ticks = [0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0]
    custom_labels = [0, 0.5, 1.0, 0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5]
    graph.set_yticks(custom_ticks)
    graph.set_yticklabels(custom_labels)

    # graph.set_xlim(trial_start_data[0] - 1000, trial_end_data[-1] + 1000)
    graph.set_xlim(trial_start_data[0] - 500, trial_end_data[-1] + 500)
    graph.set_title(title)
    graph.set_xlabel("Time (ms)")
    graph.set_ylabel("Signal       Deviation of Fixation (Deg)")

    handles, labels = plt.gca().get_legend_handles_labels()
    by_label = dict(zip(labels, handles))
    by_label['Trial Start'] = Line2D([], [], color='black', linestyle='-', label='Trial Start')
    by_label['Trial End'] = Line2D([], [], color='black', linestyle='--', label='Trial End')
    graph.legend(by_label.values(), by_label.keys(), bbox_to_anchor=(1.0, 1.15), loc='upper left')

    graph.grid(False)
    fig.savefig(png_name, dpi=100, bbox_inches='tight')
    plt.close()


def plot_graphs_for_trials(data_file, filepath_eyepos, date, run_num, start_trial, end_trial, output_folder):
    if end_trial - start_trial + 1 > 5:
        raise Exception("Sorry, max trials are 5.\n")

    if start_trial == end_trial:
        title = start_trial
        pic = start_trial
    else:
        title = "{} - {}".format(start_trial, end_trial)
        pic = "{}-to-{}".format(start_trial, end_trial)

    df = pd.read_csv(data_file)
    # trials = df['Trial'].unique()
    trials = list(range(start_trial, end_trial + 1))

    reward_rows = df[df['CodeNumber'] == 17][['Trial', 'AbsCodeTime']].reset_index(drop=True)
    punish_rows = df[df['CodeNumber'] == 15][['Trial', 'AbsCodeTime']].reset_index(drop=True)
    ttl_rows = df[(df['CodeNumber'] == 11) | (df['CodeNumber'] == 21)][
        ['Trial', 'AbsCodeTime', 'CodeNumber']].reset_index(drop=True)
    ttl_between_trials = df[df['Event_Type'] == 'TTL_ITI'][['Trial', 'TTL_pulse_start']].reset_index(drop=True)
    if start_trial == end_trial:
        ttl_between_trials = None
    else:
        ttl_between_trials = ttl_between_trials[(ttl_between_trials['Trial'] > start_trial) &
                                                (ttl_between_trials['Trial'] <= end_trial)]['TTL_pulse_start'].to_list()

    trial_start_rows = df[df['CodeNumber'] == 9][['Trial', 'AbsCodeTime']].reset_index(drop=True)
    trial_end_rows = df[df['CodeNumber'] == 18][['Trial', 'AbsCodeTime']].reset_index(drop=True)

    trial_start_time = trial_start_rows[(trial_start_rows['Trial'] >= start_trial) &
                                        (trial_start_rows['Trial'] <= end_trial)]['AbsCodeTime'].to_list()
    trial_end_time = trial_end_rows[(trial_end_rows['Trial'] >= start_trial) &
                                    (trial_end_rows['Trial'] <= end_trial)]['AbsCodeTime'].to_list()
    trial_time_data = [list(pair) for pair in zip(trial_start_time, trial_end_time)]

    baseline_rows = df[(df['CodeNumber'] == 24) | (df['CodeNumber'] == 6)][['Trial', 'CodeNumber', 'AbsCodeTime']] \
        .reset_index(drop=True)
    baseline_start = baseline_rows[(baseline_rows['Trial'] >= start_trial) &
                                   (baseline_rows['Trial'] <= end_trial)][::2]['AbsCodeTime'].to_list()
    baseline_end = baseline_rows[(baseline_rows['Trial'] >= start_trial) &
                                 (baseline_rows['Trial'] <= end_trial)][1::2]['AbsCodeTime'].to_list()

    stimulus_rows = df[(df['CodeNumber'] == 6) | (df['CodeNumber'] == 18)][
        ['Trial', 'CodeNumber', 'AbsCodeTime']].reset_index(drop=True)
    stimulus_start = stimulus_rows[(stimulus_rows['Trial'] >= start_trial) &
                                   (stimulus_rows['Trial'] <= end_trial)][::2]['AbsCodeTime'].to_list()
    stimulus_end = stimulus_rows[(stimulus_rows['Trial'] >= start_trial) &
                                 (stimulus_rows['Trial'] <= end_trial)][1::2]['AbsCodeTime'].to_list()

    df2 = pd.read_csv(filepath_eyepos)
    df2['timestamp'] = df2.index

    total_offline_time = 0
    eyepos_end_trial = trials[0] if len(trials) == 1 else trials[-1]

    for trial in range(1, eyepos_end_trial):
        total_offline_time += len(df2.iloc[0:int(df2.loc[df2['eye_pos{:02d}_magnitude'.format(trial)].last_valid_index()]['timestamp']) + 1])

    eye_pos_mag_list = ['timestamp']
    for trial in trials:
        eye_pos_mag_list.append("eye_pos{:02d}_magnitude".format(trial))
    eye_pos_data = df2[eye_pos_mag_list]

    output_image_name = "{}-run{}-signal-graph-trial-{}.png".format(date, run_num, pic)
    output_image_path = os.path.join(output_folder, output_image_name)

    plot_everything_in_one_graph(trials, trial_start_time, trial_end_time,
                                 {'start': baseline_start, 'end': baseline_end},
                                 {'start': stimulus_start, 'end': stimulus_end},
                                 reward_rows,
                                 punish_rows,
                                 ttl_rows,
                                 ttl_between_trials,
                                 eye_pos_data, total_offline_time,
                                 "{} Run {} Signal Graph for trial {}".format(date, run_num, title),
                                 output_image_path)


def plot_eye_pos_graph_for_trials(eye_pos_filepath, date, run_num, start_trial, end_trial):
    plt.rcParams.update({'font.size': 20})
    fig, graph = plt.subplots(figsize=(50, 6))

    df = pd.read_csv(eye_pos_filepath)
    df['timestamp'] = df.index

    trial = start_trial
    eye_pos_data = df.iloc[0:int(df.loc[df['eye_pos{:02d}_xcoord'.format(trial)].last_valid_index()]['timestamp']) + 1][
        ['timestamp', 'eye_pos{:02d}_magnitude'.format(trial)]]

    eye_pos_data.loc[
        eye_pos_data['eye_pos{:02d}_magnitude'.format(trial)] > 10, 'eye_pos{:02d}_magnitude'.format(trial)] = 3.5

    eye_pos_data['eye_pos{:02d}_magnitude'.format(trial)] = eye_pos_data['eye_pos{:02d}_magnitude'.format(trial)] + 1

    graph.scatter(eye_pos_data['timestamp'].to_list(), eye_pos_data['eye_pos{:02d}_magnitude'.format(trial)].to_list(),
                  marker='o', color='purple', s=5)
    # graph.plot(eye_pos_data['timestamp'].to_list(), eye_pos_data['eye_pos{:02d}'.format(trial)].to_list(), color='blue')
    graph.set_xlabel('X-axis')
    graph.set_ylabel('Y-axis')
    graph.set_title('Scatter Plot')
    fig.savefig("TEST2.png", dpi=100, bbox_inches='tight')
    plt.close()


def generate_eye_pos_heatmap(eye_pos_filepath, start_trial, end_trial, bin_size, fixation, date, run_num, output_folder):
    plt.rcParams.update({'font.size': 20})
    fig, graph = plt.subplots(figsize=(16, 12))

    if start_trial == end_trial:
        title = start_trial
        pic = start_trial
    else:
        title = "{} - {}".format(start_trial, end_trial)
        pic = "{}-to-{}".format(start_trial, end_trial)

    df = pd.read_csv(eye_pos_filepath)
    df['timestamp'] = df.index

    trials = list(range(start_trial, end_trial + 1))

    x_coord_list = []
    y_coord_list = []

    for trial_index in trials:
        eye_pos_data = \
            df.iloc[0:int(df.loc[df['eye_pos{:02d}_xcoord'.format(trial_index)].last_valid_index()]['timestamp']) + 1][
                ['timestamp', 'eye_pos{:02d}_xcoord'.format(trial_index), 'eye_pos{:02d}_ycoord'.format(trial_index)]]

        eye_pos_data.loc[eye_pos_data['eye_pos{:02d}_xcoord'.format(trial_index)] > 3.5, 'eye_pos{:02d}_xcoord'.format(
            trial_index)] = 3.5
        eye_pos_data.loc[eye_pos_data['eye_pos{:02d}_ycoord'.format(trial_index)] > 3.5, 'eye_pos{:02d}_ycoord'.format(
            trial_index)] = 3.5

        x_coord_list.append(eye_pos_data['eye_pos{:02d}_xcoord'.format(trial_index)].to_list())
        y_coord_list.append(eye_pos_data['eye_pos{:02d}_ycoord'.format(trial_index)].to_list())

    # Define color stops (positions must start at 0 and end at 1)
    positions = [0.0, 0.25, 0.5, 0.75, 1.0]
    colors = [
        (1.0, 1.0, 1.0),  # white at 0%
        (1.0, 1.0, 0.0),  # yellow at 25%
        (1.0, 0.5, 0.0),  # orange at 50%
        (1.0, 0.0, 0.0),  # red at 75%
        (1.0, 0.0, 0.0)  # red at 100%
    ]

    # Create the colormap
    custom_cmap = LinearSegmentedColormap.from_list("custom_heatmap", list(zip(positions, colors)))

    # Determine bin edges
    x_edges = np.arange(-3.5, 3.5 + bin_size, bin_size)
    y_edges = np.arange(-3.5, 3.5 + bin_size, bin_size)

    x_coord_list = np.concatenate(x_coord_list)
    y_coord_list = np.concatenate(y_coord_list)

    # Compute 2D histogram (counts in each square)
    heatmap, xedges, yedges = np.histogram2d(x_coord_list, y_coord_list, bins=[x_edges, y_edges])

    total_points = len(x_coord_list)
    heatmap_percent = (heatmap / total_points) * 100

    # Plot
    im = graph.imshow(
        heatmap_percent.T,  # transpose so x/y axes match visually
        origin='lower',  # so [0,0] is bottom-left
        extent=[x_edges[0], x_edges[-1], y_edges[0], y_edges[-1]],
        cmap=custom_cmap,  # or your custom colormap or 'hot'
        aspect='auto',
        vmin=0,
        vmax=15
    )

    # Add dashed circle: (x_center, y_center), radius
    circle = Circle((0, 0), fixation, color='blue', linestyle='--', linewidth=1, fill=False)
    graph.add_patch(circle)

    plt.colorbar(im, ax=graph, label='Percentage of Data Points (%)')
    graph.set_xlabel('X (Deg)')
    graph.set_ylabel('Y (Deg)')
    
    
    graph.set_title(
        "{} Run {} Eye Position Heatmap (Radius={}, Tile_size={}) for trial {}".format(date, run_num, fixation,
                                                                                       bin_size, title), pad=30)
                                                                                       
    output_image_name = "{}-run{}-eyepos-heatmap-rad-{}-trial-{}.png".format(date, run_num, fixation, pic)
    output_image_path = os.path.join(output_folder, output_image_name)
    
    fig.savefig(output_image_path, dpi=100, bbox_inches='tight')
    plt.close()


if __name__ == '__main__':
    target_folder = 'sess250710'    # the session folder that conains the csv folder and output folder
    date = '2025-07-10'         # date of the session
    
    tile_size = 0.1             # the tile size in the heatmap
    rad = 0.8                   # another name is fixation, the dotted radius in the heatmap
    
    first_run = 4               # the first run you want to do. 
    last_run = 4                 # last run you want to do. If you only need one run, set this the same as first_run
    
    first_trial = 1             # the first trial you want to do. 
    last_trial = 11             # last trial you want to do. If you only need one trial, set this the same as last_trial
    
    # please make sure that all the csv files are inside "csv" folder, which is inside target_folder
    input_csv_folder = os.path.join(target_folder, "csv")

    for run_num in range(first_run, last_run+1):     
        output_image_folder = os.path.join(target_folder, "{}-run{:02d}-output-images".format(target_folder, run_num))  # you can change the name of the output folder

        os.makedirs(input_csv_folder, exist_ok=True)
        os.makedirs(output_image_folder, exist_ok=True)
        
        # define signal.csv and eye_pos.csv
        filepath_signal = os.path.join(input_csv_folder, "{}-run{:02d}-signal.csv".format(target_folder, run_num))   
        filepath_eyepos = os.path.join(input_csv_folder, "{}-run{:02d}-eye_pos.csv".format(target_folder, run_num))

        # the followings are two for loops, one for signal graphs and one for heatmap graphs. 
        # Currently, each image show only one trial. If you want to put multiple trials in one image, you can add a number to trial_end. 
        # For example, trial_end = trial+1 This will generate trials 1-2, 2-3, 3-4, etc. 
        # For example, trial_end = trial+2 This will generate trials 1-3, 2-4, 3-5, etc. 
        # It may be good for the heatmap graphs, but not recommended for the signal graphs as the images will get really long. 
        for trial in range(first_trial, last_trial+1):
            trial_start = trial
            trial_end = trial
            
            if trial_end > last_trial:
                break
            plot_graphs_for_trials(filepath_signal, filepath_eyepos, date, run_num, trial_start, trial_end, output_image_folder)
        
        
        for trial in range(first_trial, last_trial+1):
            trial_start = trial
            trial_end = trial+1
            
            if trial_end > last_trial:
                break
            generate_eye_pos_heatmap(filepath_eyepos, trial_start, trial_end, tile_size, rad, date, run_num, output_image_folder)

    # plot_eye_pos_graph_for_trials('250605_PIP_25TD0605-run02-eye_pos.csv', date, run_num, 3, 1)

