import matplotlib.pyplot as plt
import numpy as np
from scipy import stats

def plot_matchup_scatter(scale, L, ax, color, index, units, titlestr, xpos, ypos, legendBool, basin):
	
	if scale == 'lin':
		x = L.Ref
		y = L.Model
		
	elif scale == 'log':
		x = np.log(L.Ref)
		y = np.log(L.Model)
	
	if legendBool == True:
		ax[index].scatter(x, y, marker='o', s=0.05, c=color, label=basin)
	else:
		ax[index].scatter(x, y, marker='o', s=0.05, c=color)

	if units == 'Ed':

		ax[index].set_xlabel('BGC-Argo float [$W \, m^{-2} \, nm^{-1}$]', fontsize=12)
		if index == 0:
			ax[index].set_ylabel('BIOPTIMOD [$W \, m^{-2} \, nm^{-1}$]', fontsize=12)

	if units == 'Kd':

		ax[index].set_xlabel('BGC-Argo float [$m^{-1}$]', fontsize=12)
		if index == 0:
			ax[index].set_ylabel('BIOPTIMOD [$m^{-1}$]', fontsize=12)


	count      = L.number()
	corr_coeff = L.correlation()
	bias       = L.bias()
	slope, intercept, r_value, p_value, std_err = stats.linregress(x,y)
	sigma      = L.RMSE()
	
	a          = intercept
	b          = slope
	
	x_max      = max(x.max(), y.max())*1.1          
	x_reg      = np.linspace(0., x_max, 50)

	ax[index].plot(x_reg, a + b*x_reg, color)
	ax[index].plot(x_reg,x_reg,'k--')
	
	if scale == 'log':
		ax[index].set_xscale('log')
		ax[index].set_yscale('log')
	
	textstr='$\mathrm{RMS}=%.2f$\n$\mathrm{Bias}=%.2f$\n$\mathrm{r}=%.2f$\n$\mathrm{Slope}=%.2f$\n$\mathrm{Y-int}=%.2f$\n$\mathrm{N}=%.2i$'%(sigma, bias, corr_coeff,b,a,count)
	
	if legendBool == True:
		ax[index].legend(loc='upper center', bbox_to_anchor=(0.5, 0.95), ncol=2, fancybox=True, shadow=True)
	
	ax[index].text(xpos, ypos, textstr, transform=ax[index].transAxes, fontsize=12, color = color, verticalalignment='top',bbox=dict(facecolor='white', alpha = 0.5, edgecolor=color))
	ax[index].set_title(titlestr, fontsize=24)
	ax[index].tick_params(axis='both', which='major', labelsize=14)
	ax[index].set_aspect('equal', adjustable='box')
	ax[index].set_xlim([0., x_max])
	ax[index].set_ylim([0., x_max])
		
	return ax[index]

def save_stat(L):
	
	x = L.Ref
	y = L.Model
	
	'''Mask values in case of any NaNs'''
	mask = ~np.isnan(x) & ~np.isnan(y)
	
	count = L.number()
	corr_coeff = L.correlation()
	bias = L.bias()
	slope, intercept, r_value, p_value, std_err = stats.linregress(x[mask],y[mask]) 
	sigma = L.RMSE()
	
	a = intercept
	b = slope

	return count, bias, sigma, r_value, b, a

