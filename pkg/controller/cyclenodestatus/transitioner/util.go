package transitioner

import (
	"time"

	"sigs.k8s.io/controller-runtime/pkg/reconcile"
	v1 "github.com/atlassian-labs/cyclops/pkg/apis/atlassian/v1"
)

// transitionToFailed transitions the current cycleNodeStatus to failed
func (t *CycleNodeStatusTransitioner) transitionToFailed(err error) (reconcile.Result, error) {
	t.cycleNodeStatus.Status.Phase = v1.CycleNodeStatusFailed
	t.cycleNodeStatus.Status.Message = err.Error()
	if err := t.rm.UpdateObject(t.cycleNodeStatus); err != nil {
		t.rm.Logger.Error(err, "unable to update cycleNodeStatus")
	}
	return reconcile.Result{}, err
}

// transitionToSuccessful transitions the current cycleNodeStatus to successful
func (t *CycleNodeStatusTransitioner) transitionToSuccessful() (reconcile.Result, error) {
	t.rm.LogEvent(t.cycleNodeStatus, "Successful", "Successfully cycled node")
	t.cycleNodeStatus.Status.Phase = v1.CycleNodeStatusSuccessful
	return reconcile.Result{}, t.rm.UpdateObject(t.cycleNodeStatus)
}

// transitionObject transitions the current cycleNodeStatus to the specified phase
func (t *CycleNodeStatusTransitioner) transitionObject(desiredPhase v1.CycleNodeStatusPhase) (reconcile.Result, error) {
	t.cycleNodeStatus.Status.Phase = desiredPhase
	if err := t.rm.UpdateObject(t.cycleNodeStatus); err != nil {
		return reconcile.Result{}, err
	}
	return reconcile.Result{
		Requeue:      true,
		RequeueAfter: transitionDuration,
	}, nil
}

// timedOut returns true if the processing of this CycleNodeStatus has been going longer
// than the timeout threshold
func (t *CycleNodeStatusTransitioner) timedOut() bool {
	return time.Now().After(t.cycleNodeStatus.Status.StartedTimestamp.Time.Add(nodeTerminationGracePeriod))
}
